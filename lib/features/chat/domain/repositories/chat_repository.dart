import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<MessageEntity>> loadMessages();

  Future<void> saveMessage(MessageEntity message);

  Future<void> clearMessages();

  Stream<Either<Failure, String>> sendMessage(
    List<MessageEntity> conversation, {
    bool useRag = true,
  });

  Stream<Either<Failure, String>> sendVoiceMessage(
    String audioFilePath, {
    bool useRag = true,
  });

  Stream<Either<Failure, String>> sendReceiptText(String extractedText);
}
