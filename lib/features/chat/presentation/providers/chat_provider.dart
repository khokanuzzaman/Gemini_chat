import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_parser.dart';
import '../../../../core/ai/rag_response_parser.dart';
import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/rag_context_builder.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/audio/voice_recorder_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/mlkit/ocr_service.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/scanner/receipt_scanner_service.dart';
import '../../../../core/scanner/scan_result.dart';
import '../../../../core/utils/either.dart';
import '../../data/datasources/openai_chat_datasource.dart';
import '../../data/datasources/openai_receipt_datasource.dart';
import '../../data/datasources/openai_voice_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../budget/presentation/providers/budget_plan_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../prediction/presentation/providers/prediction_provider.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/scan_receipt_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/send_voice_message_usecase.dart';
import '../utils/message_key.dart';

final expenseParserProvider = Provider<ExpenseParser>((ref) {
  return const ExpenseParser();
});

final ragContextBuilderProvider = Provider<RagContextBuilder>((ref) {
  return RagContextBuilder(
    localDataSource: ref.watch(expenseLocalDataSourceProvider),
    budgetPlanLocalDataSource: ref.watch(budgetPlanLocalDataSourceProvider),
    goalLocalDataSource: ref.watch(goalLocalDataSourceProvider),
    recurringLocalDataSource: ref.watch(recurringLocalDataSourceProvider),
    anomalyLoader: () => ref.read(anomalyProvider.notifier).getActiveAlerts(),
    predictionLoader: () async {
      final currentPrediction = ref.read(predictionProvider).prediction;
      if (currentPrediction != null) {
        return currentPrediction;
      }
      return ref.read(predictionProvider.notifier).getCachedPrediction();
    },
  );
});

final voiceRecorderServiceProvider = Provider<VoiceRecorderService>((ref) {
  final service = VoiceRecorderService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final receiptScannerServiceProvider = Provider<ReceiptScannerService>((ref) {
  return ReceiptScannerService(ocrService: ref.watch(ocrServiceProvider));
});

final openAiChatDataSourceProvider = Provider<OpenAiChatDataSource>((ref) {
  return OpenAiChatDataSourceImpl(
    connectivityService: ref.watch(connectivityServiceProvider),
    categoryLoader: () => ref.read(getCategoriesUseCaseProvider).call(),
  );
});

final openAiVoiceDataSourceProvider = Provider<OpenAiVoiceDataSource>((ref) {
  return OpenAiVoiceDataSourceImpl(
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final openAiReceiptDataSourceProvider = Provider<OpenAiReceiptDataSource>((
  ref,
) {
  return OpenAiReceiptDataSourceImpl(
    connectivityService: ref.watch(connectivityServiceProvider),
    categoryLoader: () => ref.read(getCategoriesUseCaseProvider).call(),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    chatDataSource: ref.watch(openAiChatDataSourceProvider),
    voiceDataSource: ref.watch(openAiVoiceDataSourceProvider),
    receiptDataSource: ref.watch(openAiReceiptDataSourceProvider),
    ragContextBuilder: ref.watch(ragContextBuilderProvider),
    isar: ref.watch(isarProvider),
  );
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final sendVoiceMessageUseCaseProvider = Provider<SendVoiceMessageUseCase>((
  ref,
) {
  return SendVoiceMessageUseCase(ref.watch(chatRepositoryProvider));
});

final scanReceiptUseCaseProvider = Provider<ScanReceiptUseCase>((ref) {
  return ScanReceiptUseCase(ref.watch(chatRepositoryProvider));
});

final chatStreamingTextProvider = StateProvider<String?>((ref) => null);
final isRespondingProvider = StateProvider<bool>((ref) => false);
final isRecordingProvider = StateProvider<bool>((ref) => false);
final isScanningProvider = StateProvider<bool>((ref) => false);
final recordingDurationProvider = StateProvider<String?>((ref) => null);
final chatErrorMessageProvider = StateProvider<String?>((ref) => null);
final openAiRateLimitSnapshotProvider = StateProvider<RateLimitSnapshot?>(
  (ref) => null,
);
final ragEnabledProvider = StateProvider<bool>((ref) => true);
final lastMessageUsedRagProvider = StateProvider<bool>((ref) => false);
final latestRagStructuredDataProvider = StateProvider<RagStructuredData?>(
  (ref) => null,
);
final ragResponseMapProvider = StateProvider<Map<String, RagResponseData>>(
  (ref) => const {},
);

final chatProvider = AsyncNotifierProvider<ChatNotifier, List<MessageEntity>>(
  ChatNotifier.new,
);

class ChatNotifier extends AsyncNotifier<List<MessageEntity>> {
  static const _voicePlaceholderText = AppStrings.voiceMessage;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  Future<List<MessageEntity>> build() async {
    ref.onDispose(() {
      _recordingTimer?.cancel();
    });

    try {
      return await ref.read(chatRepositoryProvider).loadMessages();
    } on Failure catch (failure) {
      _setError(failure.message);
      return const [];
    }
  }

  Future<void> sendMessage(String rawText) async {
    final trimmedText = rawText.trim();
    if (trimmedText.isEmpty ||
        ref.read(isRespondingProvider) ||
        ref.read(isRecordingProvider) ||
        ref.read(isScanningProvider)) {
      return;
    }

    final pendingRagContext = ref.read(ragEnabledProvider)
        ? await ref.read(ragContextBuilderProvider).buildContext(trimmedText)
        : null;

    final userMessage = MessageEntity(
      text: trimmedText,
      isUser: true,
      createdAt: DateTime.now(),
    );

    await _sendConversation(
      userMessage: userMessage,
      streamFactory: (conversation) {
        return ref.read(sendMessageUseCaseProvider)(
          conversation,
          useRag: ref.read(ragEnabledProvider),
        );
      },
      ragQuestion: trimmedText,
      ragContext: pendingRagContext,
      tokenUsageReader: () =>
          ref.read(openAiChatDataSourceProvider).latestTokenUsage,
      rateLimitReader: () =>
          ref.read(openAiChatDataSourceProvider).latestRateLimitSnapshot,
    );
  }

  Future<void> startRecording() async {
    if (ref.read(isRespondingProvider) ||
        ref.read(isRecordingProvider) ||
        ref.read(isScanningProvider)) {
      return;
    }

    try {
      await ref.read(voiceRecorderServiceProvider).startRecording();
      ref.read(isRecordingProvider.notifier).state = true;
      ref.read(recordingDurationProvider.notifier).state = _formatDuration(0);
      _startRecordingTimer();
    } on PermissionDeniedException catch (error) {
      await _appendStandaloneErrorMessage(
        error.message ?? AppStrings.micPermissionSettings,
      );
    } catch (_) {
      await _appendStandaloneErrorMessage(AppStrings.recordingStartFailed);
    }
  }

  Future<void> stopAndSendVoice() async {
    if (!ref.read(isRecordingProvider) ||
        ref.read(isRespondingProvider) ||
        ref.read(isScanningProvider)) {
      return;
    }

    _stopRecordingTimer();

    final recorder = ref.read(voiceRecorderServiceProvider);
    String? audioFilePath;

    try {
      audioFilePath = await recorder.stopRecording();
    } catch (_) {
      _resetRecordingState();
      await _appendStandaloneErrorMessage(AppStrings.recordingStopFailed);
      return;
    }

    _resetRecordingState();

    if (audioFilePath == null) {
      await _appendStandaloneErrorMessage(AppStrings.voiceMessageMissing);
      return;
    }

    final audioFile = File(audioFilePath);
    final currentMessages = [...(state.valueOrNull ?? await future)];
    final provisionalVoiceMessage = MessageEntity(
      text: _voicePlaceholderText,
      isUser: true,
      isVoice: true,
      createdAt: DateTime.now(),
    );
    var updatedConversation = [...currentMessages, provisionalVoiceMessage];
    var transcriptReceived = false;
    String? transcribedText;
    RagContext? pendingRagContext;
    final useRag = ref.read(ragEnabledProvider);

    try {
      state = AsyncData(updatedConversation);
      await _startStreaming();

      try {
        await for (final partialResponse in ref.read(
          sendVoiceMessageUseCaseProvider,
        )(audioFilePath, useRag: useRag)) {
          if (partialResponse case Left(value: final failure)) {
            await _appendErrorMessage(updatedConversation, failure);
            return;
          }

          if (partialResponse case Right(value: final responseText)) {
            if (responseText == '[RAG]') {
              ref.read(lastMessageUsedRagProvider.notifier).state = true;
              if (pendingRagContext != null) {
                ref.read(latestRagStructuredDataProvider.notifier).state =
                    pendingRagContext.data;
              }
              continue;
            }

            if (responseText.startsWith(voiceTranscriptEventPrefix)) {
              transcribedText = responseText
                  .substring(voiceTranscriptEventPrefix.length)
                  .trim();
              if (transcribedText.isNotEmpty) {
                pendingRagContext = useRag
                    ? await ref
                          .read(ragContextBuilderProvider)
                          .buildContext(transcribedText)
                    : null;
                _updateRateLimitSnapshot(
                  ref
                      .read(openAiVoiceDataSourceProvider)
                      .latestRateLimitSnapshot,
                );
                final userMessage = MessageEntity(
                  text: _buildVoiceBubbleText(transcribedText),
                  isUser: true,
                  isVoice: true,
                  createdAt: provisionalVoiceMessage.createdAt,
                );
                updatedConversation = [...currentMessages, userMessage];
                transcriptReceived = true;
                state = AsyncData(updatedConversation);
                await _saveMessage(userMessage);
              }
              continue;
            }

            ref.read(chatStreamingTextProvider.notifier).state = responseText;
          }
        }

        if (!transcriptReceived) {
          _updateRateLimitSnapshot(
            ref.read(openAiVoiceDataSourceProvider).latestRateLimitSnapshot,
          );
          await _appendErrorMessage(
            currentMessages,
            const TranscriptionFailedFailure(),
          );
          return;
        }

        await _finalizeAssistantMessage(
          updatedConversation,
          ragQuestion: transcribedText,
          ragContext: pendingRagContext,
          tokenUsageReader: () =>
              ref.read(openAiChatDataSourceProvider).latestTokenUsage,
          rateLimitReader: () =>
              ref.read(openAiChatDataSourceProvider).latestRateLimitSnapshot ??
              ref.read(openAiVoiceDataSourceProvider).latestRateLimitSnapshot,
        );
      } on Failure catch (failure) {
        _updateRateLimitSnapshot(
          ref.read(openAiVoiceDataSourceProvider).latestRateLimitSnapshot ??
              ref.read(openAiChatDataSourceProvider).latestRateLimitSnapshot,
        );
        await _appendErrorMessage(
          transcriptReceived ? updatedConversation : currentMessages,
          failure,
        );
      } catch (_) {
        _updateRateLimitSnapshot(
          ref.read(openAiVoiceDataSourceProvider).latestRateLimitSnapshot ??
              ref.read(openAiChatDataSourceProvider).latestRateLimitSnapshot,
        );
        await _appendErrorMessage(
          transcriptReceived ? updatedConversation : currentMessages,
          const GeneralFailure(),
        );
      } finally {
        await _stopStreaming();
      }
    } finally {
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }
  }

  Future<void> scanFromCamera() async {
    await _scanReceipt(
      scanAction: () =>
          ref.read(receiptScannerServiceProvider).pickAndScanFromCamera(),
    );
  }

  Future<void> scanFromGallery() async {
    await _scanReceipt(
      scanAction: () =>
          ref.read(receiptScannerServiceProvider).pickAndScanFromGallery(),
    );
  }

  Future<bool> clearChat() async {
    if (ref.read(isRespondingProvider) ||
        ref.read(isRecordingProvider) ||
        ref.read(isScanningProvider)) {
      return false;
    }

    try {
      await _stopStreaming();
      await ref.read(chatRepositoryProvider).clearMessages();
      ref.read(ragResponseMapProvider.notifier).state = const {};
      ref.read(latestRagStructuredDataProvider.notifier).state = null;
      state = const AsyncData([]);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      return false;
    } catch (error) {
      _setError('Failed to clear chat: $error');
      return false;
    }
  }

  void toggleRag() {
    if (ref.read(isRespondingProvider) ||
        ref.read(isRecordingProvider) ||
        ref.read(isScanningProvider)) {
      return;
    }

    final notifier = ref.read(ragEnabledProvider.notifier);
    notifier.state = !notifier.state;
  }

  Future<void> _scanReceipt({
    required Future<ScanResult> Function() scanAction,
  }) async {
    if (ref.read(isRespondingProvider) ||
        ref.read(isRecordingProvider) ||
        ref.read(isScanningProvider)) {
      return;
    }

    ref.read(isScanningProvider.notifier).state = true;

    try {
      final result = await scanAction();
      if (!result.success) {
        switch (result.error) {
          case 'cancelled':
            return;
          case 'permission_denied':
            await _appendStandaloneErrorMessage(
              AppStrings.cameraPermissionSettings,
            );
            return;
          case 'text_not_found':
            await _appendStandaloneErrorMessage(AppStrings.receiptTextNotFound);
            return;
          case 'invalid_format':
            await _appendStandaloneErrorMessage(
              AppStrings.receiptInvalidFormat,
            );
            return;
          default:
            await _appendStandaloneErrorMessage(AppStrings.receiptScanFailed);
            return;
        }
      }

      final extractedText = result.text?.trim();
      if (extractedText == null || extractedText.isEmpty) {
        return;
      }

      if (result.warnings.isNotEmpty) {
        _setError(
          'Receipt check score: ${result.score}/100. ${result.warnings.last}',
        );
      } else if (result.wasAutoCropped) {
        _setError(AppStrings.receiptAutoCrop);
      }

      final userMessage = MessageEntity(
        text: '📷 Receipt scan করলাম',
        isUser: true,
        isReceipt: true,
        createdAt: DateTime.now(),
      );

      await _sendConversation(
        userMessage: userMessage,
        streamFactory: (_) {
          return ref.read(scanReceiptUseCaseProvider)(extractedText);
        },
        tokenUsageReader: () =>
            ref.read(openAiReceiptDataSourceProvider).latestTokenUsage,
        rateLimitReader: () =>
            ref.read(openAiReceiptDataSourceProvider).latestRateLimitSnapshot,
      );
    } on Failure catch (failure) {
      await _appendStandaloneErrorMessage(failure.message);
    } catch (_) {
      await _appendStandaloneErrorMessage(AppStrings.receiptScanFailed);
    } finally {
      ref.read(isScanningProvider.notifier).state = false;
    }
  }

  Future<void> _sendConversation({
    required MessageEntity userMessage,
    required Stream<Either<Failure, String>> Function(List<MessageEntity>)
    streamFactory,
    String? ragQuestion,
    RagContext? ragContext,
    required TokenUsage? Function() tokenUsageReader,
    required RateLimitSnapshot? Function() rateLimitReader,
  }) async {
    final currentMessages = [...(state.valueOrNull ?? await future)];
    final updatedConversation = [...currentMessages, userMessage];

    state = AsyncData(updatedConversation);
    await _saveMessage(userMessage);
    await _startStreaming();

    try {
      await for (final partialResponse in streamFactory(updatedConversation)) {
        if (partialResponse case Left(value: final failure)) {
          _updateRateLimitSnapshot(rateLimitReader());
          await _appendErrorMessage(updatedConversation, failure);
          return;
        }

        if (partialResponse case Right(value: final responseText)) {
          if (responseText == '[RAG]') {
            ref.read(lastMessageUsedRagProvider.notifier).state = true;
            if (ragContext != null) {
              ref.read(latestRagStructuredDataProvider.notifier).state =
                  ragContext.data;
            }
            continue;
          }
          ref.read(chatStreamingTextProvider.notifier).state = responseText;
        }
      }

      await _finalizeAssistantMessage(
        updatedConversation,
        ragQuestion: ragQuestion,
        ragContext: ragContext,
        tokenUsageReader: tokenUsageReader,
        rateLimitReader: rateLimitReader,
      );
    } on Failure catch (failure) {
      _updateRateLimitSnapshot(rateLimitReader());
      await _appendErrorMessage(updatedConversation, failure);
    } catch (_) {
      _updateRateLimitSnapshot(rateLimitReader());
      await _appendErrorMessage(updatedConversation, const GeneralFailure());
    } finally {
      await _stopStreaming();
    }
  }

  Future<void> _finalizeAssistantMessage(
    List<MessageEntity> updatedConversation, {
    String? ragQuestion,
    RagContext? ragContext,
    required TokenUsage? Function() tokenUsageReader,
    required RateLimitSnapshot? Function() rateLimitReader,
  }) async {
    final responseText = (ref.read(chatStreamingTextProvider) ?? '').trim();
    if (responseText.isEmpty) {
      await _appendErrorMessage(updatedConversation, const GeneralFailure());
      return;
    }

    final tokenUsage = tokenUsageReader();
    _updateRateLimitSnapshot(rateLimitReader());
    final usedRag = ref.read(lastMessageUsedRagProvider);
    final ragResponse = usedRag && ragQuestion != null
        ? _buildRagResponseData(responseText, ragQuestion, ragContext?.data)
        : null;

    final assistantMessage = MessageEntity(
      text: responseText,
      isUser: false,
      createdAt: DateTime.now(),
      usedRagContext: usedRag,
      isRag: ragResponse != null,
      ragType: ragResponse?.type,
      promptTokenCount: tokenUsage?.promptTokens,
      outputTokenCount: tokenUsage?.outputTokens,
      totalTokenCount: tokenUsage?.totalTokens,
    );

    state = AsyncData([...updatedConversation, assistantMessage]);
    await _saveMessage(assistantMessage);
    if (ragResponse != null) {
      _storeRagResponse(assistantMessage, ragResponse);
    }
  }

  Future<void> _startStreaming() async {
    ref.read(isRespondingProvider.notifier).state = true;
    ref.read(chatStreamingTextProvider.notifier).state = '';
    ref.read(lastMessageUsedRagProvider.notifier).state = false;
    ref.read(latestRagStructuredDataProvider.notifier).state = null;
  }

  Future<void> _stopStreaming() async {
    ref.read(isRespondingProvider.notifier).state = false;
    ref.read(chatStreamingTextProvider.notifier).state = null;
  }

  Future<void> _saveMessage(MessageEntity message) async {
    try {
      await ref.read(chatRepositoryProvider).saveMessage(message);
    } on Failure catch (failure) {
      _setError(failure.message);
    }
  }

  Future<void> _appendStandaloneErrorMessage(String message) async {
    final currentMessages = [...(state.valueOrNull ?? await future)];
    await _appendErrorMessage(currentMessages, GeneralFailure(message));
  }

  Future<void> _appendErrorMessage(
    List<MessageEntity> baseConversation,
    Failure failure,
  ) async {
    final errorMessage = MessageEntity(
      text: failure.message,
      isUser: false,
      isError: true,
      createdAt: DateTime.now(),
    );
    state = AsyncData([...baseConversation, errorMessage]);
    await _saveMessage(errorMessage);
  }

  void _setError(String message) {
    ref.read(chatErrorMessageProvider.notifier).state = message;
  }

  void _updateRateLimitSnapshot(RateLimitSnapshot? snapshot) {
    if (snapshot == null) {
      return;
    }

    ref.read(openAiRateLimitSnapshotProvider.notifier).state = snapshot;
  }

  RagResponseData _buildRagResponseData(
    String responseText,
    String ragQuestion,
    RagStructuredData? structuredData,
  ) {
    var ragData = RagResponseParser.parse(responseText, ragQuestion);
    if (structuredData == null) {
      return ragData;
    }

    final highlightedCategory =
        ragData.highlightedCategory ??
        _topCategory(structuredData.categoryTotals);
    final periodTransactions = switch (ragData.type) {
      RagResponseType.todaySummary => structuredData.todayExpenses,
      RagResponseType.categoryBreakdown =>
        structuredData.periodExpenses
            .where((expense) => expense.category == highlightedCategory)
            .toList(growable: false),
      _ => structuredData.recentExpenses,
    };
    final totalAmount = switch (ragData.type) {
      RagResponseType.comparison => structuredData.thisMonthTotal,
      RagResponseType.todaySummary => structuredData.todayExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      ),
      _ => structuredData.periodTotal,
    };

    return ragData.copyWith(
      monthName: structuredData.monthName,
      categoryData: structuredData.categoryTotals,
      totalAmount: totalAmount,
      lastMonthTotal: structuredData.lastMonthTotal,
      lastMonthCategoryData: structuredData.lastMonthCategoryTotals,
      lastMonthName: structuredData.lastMonthName,
      transactionCount: structuredData.transactionCount,
      highlightedCategory: highlightedCategory,
      recentItems: periodTransactions
          .take(10)
          .map(
            (expense) => RecentTransaction(
              description: expense.description,
              category: expense.category,
              amount: expense.amount,
              date: expense.date.toIso8601String(),
            ),
          )
          .toList(growable: false),
    );
  }

  String? _topCategory(Map<String, double> totals) {
    if (totals.isEmpty) {
      return null;
    }

    final sorted = totals.entries.toList(growable: false)
      ..sort((first, second) => second.value.compareTo(first.value));
    return sorted.first.key;
  }

  void _storeRagResponse(MessageEntity message, RagResponseData ragResponse) {
    final key = buildChatMessageKey(message);
    final notifier = ref.read(ragResponseMapProvider.notifier);
    notifier.state = {...notifier.state, key: ragResponse};
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingSeconds += 1;
      ref.read(recordingDurationProvider.notifier).state = _formatDuration(
        _recordingSeconds,
      );
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _resetRecordingState() {
    _recordingSeconds = 0;
    ref.read(isRecordingProvider.notifier).state = false;
    ref.read(recordingDurationProvider.notifier).state = null;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _buildVoiceBubbleText(String transcript) {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) {
      return _voicePlaceholderText;
    }

    if (_containsDevanagari(trimmed) || !_containsBengali(trimmed)) {
      return _voicePlaceholderText;
    }

    return '🎤 $trimmed';
  }

  bool _containsBengali(String text) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(text);
  }

  bool _containsDevanagari(String text) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(text);
  }
}
