import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/expense_local_datasource.dart';

final isarProvider = Provider<Isar>(
  (ref) =>
      throw UnimplementedError('Isar must be initialized before app startup.'),
);

final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  return ExpenseLocalDataSource(ref.watch(isarProvider));
});
