import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/ai/rag_context_builder.dart';
import 'package:gemini_chat/core/ai/rag_response_parser.dart';
import 'package:gemini_chat/core/database/expense_local_datasource.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/errors/failures.dart';
import 'package:gemini_chat/core/utils/either.dart';
import 'package:gemini_chat/features/chat/domain/entities/message_entity.dart';
import 'package:gemini_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:gemini_chat/features/chat/presentation/providers/chat_provider.dart';
import 'package:gemini_chat/features/chat/presentation/screens/chat_screen.dart';
import 'package:gemini_chat/features/chat/presentation/widgets/message_bubble.dart';

class _FakeChatRepository implements ChatRepository {
  bool? lastUseRag;
  List<MessageEntity> lastConversation = const [];

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
  }) async* {
    lastConversation = conversation;
    lastUseRag = useRag;
    yield const Left(GeneralFailure('test error'));
  }

  @override
  Stream<Either<Failure, String>> sendReceiptText(String extractedText) =>
      const Stream.empty();

  @override
  Stream<Either<Failure, String>> sendVoiceMessage(
    String audioFilePath, {
    bool useRag = true,
  }) => const Stream.empty();
}

class _FakeExpenseLocalDataSource extends ExpenseLocalDataSource {
  _FakeExpenseLocalDataSource() : super(_StubIsar());

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

class _StubIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  testWidgets('RAG toggle button updates provider state and icon', (
    tester,
  ) async {
    final fakeRepository = _FakeChatRepository();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeRepository),
        ragContextBuilderProvider.overrideWithValue(
          RagContextBuilder(localDataSource: _FakeExpenseLocalDataSource()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await _pumpChatFrames(tester);

    expect(container.read(ragEnabledProvider), isTrue);
    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    expect(find.byIcon(Icons.psychology_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.psychology_rounded));
    await _pumpChatFrames(tester);

    expect(container.read(ragEnabledProvider), isFalse);
    expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
    expect(find.byIcon(Icons.psychology_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.psychology_outlined));
    await _pumpChatFrames(tester);

    expect(container.read(ragEnabledProvider), isTrue);
    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    expect(find.byIcon(Icons.psychology_outlined), findsNothing);
  });

  testWidgets('send message respects current RAG toggle state', (tester) async {
    final fakeRepository = _FakeChatRepository();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeRepository),
        ragContextBuilderProvider.overrideWithValue(
          RagContextBuilder(localDataSource: _FakeExpenseLocalDataSource()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await _pumpChatFrames(tester);

    await tester.tap(find.byIcon(Icons.psychology_rounded));
    await _pumpChatFrames(tester);
    expect(container.read(ragEnabledProvider), isFalse);

    await container
        .read(chatProvider.notifier)
        .sendMessage('এই মাসে কত খরচ হয়েছে?');
    await _pumpChatFrames(tester);

    expect(fakeRepository.lastUseRag, isFalse);

    await tester.tap(find.byIcon(Icons.psychology_outlined));
    await _pumpChatFrames(tester);
    expect(container.read(ragEnabledProvider), isTrue);

    await container.read(chatProvider.notifier).sendMessage('Food এ কত গেছে?');
    await _pumpChatFrames(tester);

    expect(fakeRepository.lastUseRag, isTrue);
  });

  testWidgets('RAG monthly summary renders structured summary card', (
    tester,
  ) async {
    const ragData = RagResponseData(
      type: RagResponseType.monthlySummary,
      aiText: 'Food এ budget বেশি যাচ্ছে।',
      monthName: 'এপ্রিল ২০২৬',
      totalAmount: 8550,
      lastMonthTotal: 8050,
      transactionCount: 31,
      categoryData: {
        'Food': 3200,
        'Shopping': 2550,
        'Transport': 1800,
        'Other': 1000,
      },
      insights: ['Food এ budget বেশি যাচ্ছে।'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MessageBubble(
              text: 'summary',
              isUser: false,
              isRag: true,
              createdAt: DateTime(2026, 4, 2, 10, 30),
              ragData: ragData,
              onOpenAnalytics: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('এই মাসের সারসংক্ষেপ'), findsOneWidget);
    expect(find.text('মোট খরচ'), findsOneWidget);
    expect(find.textContaining('আপনার data থেকে'), findsOneWidget);
  });

  testWidgets('RAG category breakdown renders category card', (tester) async {
    const ragData = RagResponseData(
      type: RagResponseType.categoryBreakdown,
      aiText: 'গড়ে দিনে ৳১০৭ খরচ হচ্ছে Food এ',
      monthName: 'এপ্রিল ২০২৬',
      totalAmount: 8550,
      highlightedCategory: 'Food',
      categoryData: {'Food': 3200, 'Shopping': 2550},
      recentItems: [
        RecentTransaction(
          description: 'দুপুরের খাবার',
          category: 'Food',
          amount: 150,
          date: '2026-04-03T13:30:00.000',
        ),
        RecentTransaction(
          description: 'নাস্তা',
          category: 'Food',
          amount: 30,
          date: '2026-04-04T08:30:00.000',
        ),
      ],
      insights: ['গড়ে দিনে ৳১০৭ খরচ হচ্ছে Food এ'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MessageBubble(
              text: 'category',
              isUser: false,
              isRag: true,
              createdAt: DateTime(2026, 4, 2, 10, 30),
              ragData: ragData,
              onOpenAnalytics: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category বিশ্লেষণ'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('সাম্প্রতিক খরচ'), findsOneWidget);
  });

  testWidgets('recording composer shows clear Bengali voice actions', (
    tester,
  ) async {
    final fakeRepository = _FakeChatRepository();
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeRepository),
        ragContextBuilderProvider.overrideWithValue(
          RagContextBuilder(localDataSource: _FakeExpenseLocalDataSource()),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(isRecordingProvider.notifier).state = true;
    container.read(recordingDurationProvider.notifier).state = '0:09';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await _pumpChatFrames(tester);

    expect(find.text('ভয়েস রেকর্ড হচ্ছে'), findsOneWidget);
    expect(find.text('0:09'), findsOneWidget);
    expect(find.text('শেষ হলে পাশের বাটনে চাপুন'), findsOneWidget);
    expect(find.text('পাঠান'), findsOneWidget);
  });

  testWidgets('voice bubble shows transcript with voice label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            text: '🎤 মার্চ মাসের খরচ কত?',
            isUser: true,
            isVoice: true,
            createdAt: DateTime(2026, 4, 2, 10, 30),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ভয়েস মেসেজ'), findsOneWidget);
    expect(find.text('মার্চ মাসের খরচ কত?'), findsOneWidget);
    expect(find.text('Transcript দেখা যাচ্ছে না'), findsNothing);
  });
}

void _noop() {}

Future<void> _pumpChatFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 280));
}
