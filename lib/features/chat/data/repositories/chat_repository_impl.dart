import 'package:isar/isar.dart';

import '../../../../core/ai/rag_context_builder.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/openai_chat_datasource.dart';
import '../datasources/openai_receipt_datasource.dart';
import '../datasources/openai_voice_datasource.dart';
import '../models/message_model.dart';

const voiceTranscriptEventPrefix = '__voice_transcript__:';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required OpenAiChatDataSource chatDataSource,
    required OpenAiVoiceDataSource voiceDataSource,
    required OpenAiReceiptDataSource receiptDataSource,
    required RagContextBuilder ragContextBuilder,
    required Isar isar,
  }) : _chatDataSource = chatDataSource,
       _voiceDataSource = voiceDataSource,
       _receiptDataSource = receiptDataSource,
       _ragContextBuilder = ragContextBuilder,
       _isar = isar;

  final OpenAiChatDataSource _chatDataSource;
  final OpenAiVoiceDataSource _voiceDataSource;
  final OpenAiReceiptDataSource _receiptDataSource;
  final RagContextBuilder _ragContextBuilder;
  final Isar _isar;

  @override
  Future<List<MessageEntity>> loadMessages() async {
    try {
      final messages = await _isar.messageModels.where().findAll();
      messages.sort(
        (first, second) => first.createdAt.compareTo(second.createdAt),
      );

      return messages
          .map((message) => message.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> saveMessage(MessageEntity message) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      await _isar.writeTxn(() async {
        await _isar.messageModels.put(messageModel);
      });
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> clearMessages() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.messageModels.clear();
      });
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Stream<Either<Failure, String>> sendMessage(
    List<MessageEntity> conversation, {
    bool useRag = true,
  }) async* {
    try {
      final lastUserIndex = conversation.lastIndexWhere(
        (message) => message.isUser,
      );
      if (lastUserIndex == -1) {
        yield const Left(GeneralFailure());
        return;
      }

      final history = conversation.take(lastUserIndex).toList(growable: false);
      final newMessage = conversation[lastUserIndex].text;
      final ragContext = useRag
          ? await _ragContextBuilder.buildContext(newMessage)
          : null;

      await for (final chunk in _chatDataSource.sendMessage(
        history,
        newMessage,
        ragContext: ragContext?.textForAi,
      )) {
        yield Right(chunk);
      }
    } on NoInternetException {
      yield const Left(NoInternetFailure());
    } on InvalidApiKeyException catch (error) {
      yield Left(InvalidApiKeyFailure(error.message));
    } on RequestTimeoutException {
      yield const Left(TimeoutFailure());
    } on QuotaExceededException {
      yield const Left(QuotaExceededFailure());
    } on GeneralException catch (error) {
      yield Left(
        GeneralFailure(error.message ?? const GeneralFailure().message),
      );
    } catch (_) {
      yield const Left(GeneralFailure());
    }
  }

  @override
  Stream<Either<Failure, String>> sendVoiceMessage(
    String audioFilePath, {
    bool useRag = true,
  }) async* {
    try {
      final transcribedText = await _voiceDataSource.transcribeAudio(
        audioFilePath,
      );
      yield Right('$voiceTranscriptEventPrefix$transcribedText');

      final history = await loadMessages();
      final ragContext = useRag
          ? await _ragContextBuilder.buildContext(transcribedText)
          : null;
      await for (final chunk in _chatDataSource.sendMessage(
        history,
        transcribedText,
        ragContext: ragContext?.textForAi,
      )) {
        yield Right(chunk);
      }
    } on NoInternetException {
      yield const Left(NoInternetFailure());
    } on InvalidApiKeyException catch (error) {
      yield Left(InvalidApiKeyFailure(error.message));
    } on RequestTimeoutException {
      yield const Left(TimeoutFailure());
    } on QuotaExceededException {
      yield const Left(QuotaExceededFailure());
    } on FileTooLargeException catch (error) {
      yield Left(FileTooLargeFailure(error.message));
    } on TranscriptionFailedException catch (error) {
      yield Left(TranscriptionFailedFailure(error.message));
    } on GeneralException catch (error) {
      yield Left(
        GeneralFailure(error.message ?? const GeneralFailure().message),
      );
    } catch (_) {
      yield const Left(GeneralFailure());
    }
  }

  @override
  Stream<Either<Failure, String>> sendReceiptText(String extractedText) async* {
    try {
      final normalizedText = extractedText.trim();
      if (normalizedText.length < 20) {
        throw const OcrFailedException();
      }

      await for (final chunk in _receiptDataSource.parseReceipt(
        normalizedText,
      )) {
        yield Right(chunk);
      }
    } on NoInternetException {
      yield const Left(NoInternetFailure());
    } on InvalidApiKeyException catch (error) {
      yield Left(InvalidApiKeyFailure(error.message));
    } on RequestTimeoutException {
      yield const Left(TimeoutFailure());
    } on QuotaExceededException {
      yield const Left(QuotaExceededFailure());
    } on OcrFailedException catch (error) {
      yield Left(OcrFailedFailure(error.message));
    } on GeneralException catch (error) {
      yield Left(
        GeneralFailure(error.message ?? const GeneralFailure().message),
      );
    } catch (_) {
      yield const Left(GeneralFailure());
    }
  }
}
