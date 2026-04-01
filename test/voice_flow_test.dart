import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/ai/rag_context_builder.dart';
import 'package:gemini_chat/core/database/expense_local_datasource.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/errors/failures.dart';
import 'package:gemini_chat/core/utils/either.dart';
import 'package:gemini_chat/core/audio/voice_recorder_service.dart';
import 'package:gemini_chat/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gemini_chat/features/chat/domain/entities/message_entity.dart';
import 'package:gemini_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:gemini_chat/features/chat/presentation/providers/chat_provider.dart';

class _StubIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _EmptyExpenseLocalDataSource extends ExpenseLocalDataSource {
  _EmptyExpenseLocalDataSource() : super(_StubIsar());

  @override
  Future<List<ExpenseRecordModel>> getThisMonthExpenses() async => const [];

  @override
  Future<List<ExpenseRecordModel>> getTodayExpenses() async => const [];

  @override
  Future<List<ExpenseRecordModel>> getLastMonthExpenses() async => const [];

  @override
  Future<List<ExpenseRecordModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async => const [];
}

class _FakeRagContextBuilder extends RagContextBuilder {
  _FakeRagContextBuilder()
    : super(localDataSource: _EmptyExpenseLocalDataSource());

  String? lastQuestion;

  @override
  Future<RagContext?> buildContext(String userQuestion) async {
    lastQuestion = userQuestion;
    return RagContext(
      textForAi: 'ctx::$userQuestion',
      data: RagStructuredData(
        thisMonthTotal: 2400,
        lastMonthTotal: 1800,
        categoryTotals: const {'Food': 1200, 'Transport': 600},
        todayExpenses: const [],
        recentExpenses: const [],
        monthName: 'মার্চ ২০২৫',
        transactionCount: 4,
        periodTotal: 1200,
        periodExpenses: const [],
        lastMonthCategoryTotals: const {'Food': 900},
        lastMonthExpenses: const [],
        lastMonthName: 'ফেব্রুয়ারি ২০২৫',
        referenceDate: DateTime(2025, 3, 1),
      ),
    );
  }
}

class _FakeVoiceRecorderService extends VoiceRecorderService {
  _FakeVoiceRecorderService(this._audioPath);

  final String _audioPath;

  @override
  Future<String?> stopRecording() async => _audioPath;

  @override
  Future<void> startRecording() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> dispose() async {}
}

class _FakeVoiceChatRepository implements ChatRepository {
  bool? lastUseRag;

  @override
  Future<void> clearMessages() async {}

  @override
  Future<List<MessageEntity>> loadMessages() async => const [];

  @override
  Future<void> saveMessage(MessageEntity message) async {}

  @override
  Stream<Either<Failure, String>> sendMessage(
    List<MessageEntity> conversation, {
    bool useRag = true,
  }) async* {}

  @override
  Stream<Either<Failure, String>> sendReceiptText(
    String extractedText,
  ) async* {}

  @override
  Stream<Either<Failure, String>> sendVoiceMessage(
    String audioFilePath, {
    bool useRag = true,
  }) async* {
    lastUseRag = useRag;
    yield const Right('$voiceTranscriptEventPrefixমার্চ ২০২৫ মাসের খরচ কত?');
    if (useRag) {
      yield const Right('[RAG]');
    }
    yield const Right('মার্চ ২০২৫ এ মোট খরচ ৳১,২০০।');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  test('voice flow applies RAG metadata when enabled', () async {
    final audioFile = File(
      '${Directory.systemTemp.path}/voice_rag_enabled_test.m4a',
    );
    await audioFile.writeAsBytes(const [1, 2, 3]);

    final fakeRepository = _FakeVoiceChatRepository();
    final fakeRagBuilder = _FakeRagContextBuilder();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeRepository),
        ragContextBuilderProvider.overrideWithValue(fakeRagBuilder),
        voiceRecorderServiceProvider.overrideWithValue(
          _FakeVoiceRecorderService(audioFile.path),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(chatProvider.future);
    container.read(isRecordingProvider.notifier).state = true;

    await container.read(chatProvider.notifier).stopAndSendVoice();

    final messages = container.read(chatProvider).valueOrNull ?? const [];
    expect(fakeRepository.lastUseRag, isTrue);
    expect(fakeRagBuilder.lastQuestion, 'মার্চ ২০২৫ মাসের খরচ কত?');
    expect(messages, hasLength(2));
    expect(messages.first.isVoice, isTrue);
    expect(messages.first.text, '🎤 মার্চ ২০২৫ মাসের খরচ কত?');
    expect(messages.last.isRag, isTrue);
    expect(messages.last.usedRagContext, isTrue);
    expect(messages.last.ragType?.name, 'monthlySummary');
    expect(
      container.read(latestRagStructuredDataProvider)?.monthName,
      'মার্চ ২০২৫',
    );
    expect(container.read(ragResponseMapProvider), isNotEmpty);
  });

  test('voice flow respects RAG toggle off', () async {
    final audioFile = File(
      '${Directory.systemTemp.path}/voice_rag_disabled_test.m4a',
    );
    await audioFile.writeAsBytes(const [1, 2, 3]);

    final fakeRepository = _FakeVoiceChatRepository();
    final fakeRagBuilder = _FakeRagContextBuilder();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeRepository),
        ragContextBuilderProvider.overrideWithValue(fakeRagBuilder),
        voiceRecorderServiceProvider.overrideWithValue(
          _FakeVoiceRecorderService(audioFile.path),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(chatProvider.future);
    container.read(ragEnabledProvider.notifier).state = false;
    container.read(isRecordingProvider.notifier).state = true;

    await container.read(chatProvider.notifier).stopAndSendVoice();

    final messages = container.read(chatProvider).valueOrNull ?? const [];
    expect(fakeRepository.lastUseRag, isFalse);
    expect(fakeRagBuilder.lastQuestion, isNull);
    expect(messages, hasLength(2));
    expect(messages.last.isRag, isFalse);
    expect(messages.last.usedRagContext, isFalse);
    expect(container.read(ragResponseMapProvider), isEmpty);
  });
}
