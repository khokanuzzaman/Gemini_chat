import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'real Isar save refreshes dashboard monthly total and category totals',
    () async {
      await Isar.initializeIsarCore(
        libraries: {
          Abi.current():
              '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib',
        },
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'smartspend-dashboard-',
      );
      final isar = await Isar.open(
        [ExpenseRecordModelSchema],
        directory: tempDir.path,
        name: 'dashboard_refresh_test',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final container = ProviderContainer(
        overrides: [isarProvider.overrideWithValue(isar)],
      );
      addTearDown(container.dispose);

      final initialDashboard = await container.read(
        dashboardControllerProvider.future,
      );
      expect(initialDashboard.thisMonthTotal, 0);
      expect(initialDashboard.categoryTotals, isEmpty);

      final error = await container
          .read(expenseMutationControllerProvider)
          .saveDetectedExpense(
            const ExpenseData(
              amount: 300,
              category: 'Bill',
              description: 'খাবারের বিল',
              date: 'today',
            ),
          );

      expect(error, isNull);

      final updatedDashboard = await container.read(
        dashboardControllerProvider.future,
      );

      expect(updatedDashboard.thisMonthTotal, 300);
      expect(updatedDashboard.transactionCount, 1);
      expect(updatedDashboard.categoryTotals['Bill'], 300);
      expect(updatedDashboard.recentExpenses, hasLength(1));
      expect(updatedDashboard.todayExpenses, hasLength(1));
    },
  );
}
