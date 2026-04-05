import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/split/domain/entities/split_bill_entity.dart';
import 'package:gemini_chat/features/split/domain/repositories/split_bill_repository.dart';
import 'package:gemini_chat/features/split/presentation/providers/split_bill_provider.dart';
import 'package:gemini_chat/features/split/presentation/screens/split_bill_screen.dart';

class _FakeSplitBillRepository implements SplitBillRepository {
  _FakeSplitBillRepository(this._splits);

  final List<SplitBillEntity> _splits;

  @override
  Future<List<SplitBillEntity>> getAllSplits() async {
    final items = [..._splits]..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Future<void> deleteSplit(int id) async {
    _splits.removeWhere((split) => split.id == id);
  }

  @override
  Future<void> markSettled(int id) async {
    final index = _splits.indexWhere((split) => split.id == id);
    if (index == -1) {
      return;
    }
    _splits[index] = _splits[index].copyWith(isSettled: true);
  }

  @override
  Future<void> saveSplit(SplitBillEntity split) async {
    _splits.add(split);
  }

  @override
  Future<void> updateSplit(SplitBillEntity split) async {
    final index = _splits.indexWhere((item) => item.id == split.id);
    if (index != -1) {
      _splits[index] = split;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  testWidgets('completed tab stays selected after provider refresh', (
    tester,
  ) async {
    final repository = _FakeSplitBillRepository([
      _split(id: 1, title: 'Active split', isSettled: false),
      _split(id: 2, title: 'Settled split', isSettled: true),
    ]);
    final container = ProviderContainer(
      overrides: [splitBillRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SplitBillScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('split-tab-settled')));
    await tester.pumpAndSettle();

    expect(find.text('Settled split'), findsOneWidget);
    expect(find.text('Active split'), findsNothing);

    await container.read(splitBillProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(find.text('Settled split'), findsOneWidget);
    expect(find.text('Active split'), findsNothing);
  });

  testWidgets('mark settled moves split into completed tab', (tester) async {
    final repository = _FakeSplitBillRepository([
      _split(id: 1, title: 'Travel dinner', isSettled: false),
    ]);
    final container = ProviderContainer(
      overrides: [splitBillRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SplitBillScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Travel dinner'), findsOneWidget);

    await tester.tap(find.byKey(const Key('split-action-settle-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'সম্পন্ন'));
    await tester.pumpAndSettle();

    expect(find.text('Travel dinner'), findsOneWidget);
    expect(find.text('✅ সম্পন্ন'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'সম্পন্ন'), findsOneWidget);
  });
}

SplitBillEntity _split({
  required int id,
  required String title,
  required bool isSettled,
}) {
  return SplitBillEntity(
    id: id,
    title: title,
    totalAmount: 1200,
    persons: const [
      SplitPerson(name: 'আমি', amountPaid: 1200, shareAmount: 600),
      SplitPerson(name: 'রহিম', amountPaid: 0, shareAmount: 600),
    ],
    date: DateTime(2026, 4, 5),
    notes: null,
    isSettled: isSettled,
    category: 'Food',
  );
}
