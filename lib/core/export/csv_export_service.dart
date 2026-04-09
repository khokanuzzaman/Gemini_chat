import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/expense/domain/entities/expense_entity.dart';

/// Builds and writes expense reports as CSV files.
class CsvExportService {
  const CsvExportService();

  /// Exports the provided expenses to a temporary CSV file.
  Future<File> exportToCSV({
    required List<ExpenseEntity> expenses,
    required String fileName,
  }) async {
    final rows = <List<dynamic>>[
      ['তারিখ', 'বিবরণ', 'Category', 'পরিমাণ (৳)', 'Manual'],
    ];

    for (final expense in expenses) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(expense.date),
        expense.description,
        expense.category,
        expense.amount.toStringAsFixed(2),
        expense.isManual ? 'হ্যাঁ' : 'না',
      ]);
    }

    rows
      ..add([])
      ..add([
        'মোট খরচ',
        '',
        '',
        expenses
            .fold<double>(0, (sum, expense) => sum + expense.amount)
            .toStringAsFixed(2),
        '',
      ])
      ..add(['মোট transactions', '', '', expenses.length.toString(), '']);

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csvData, encoding: utf8);
    return file;
  }

  /// Generates a human-readable CSV file name for the selected range.
  String generateFileName({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final formatter = DateFormat('MMM_yyyy', 'en_US');
    final start = formatter.format(startDate);
    final end = formatter.format(endDate);
    if (start == end) {
      return 'PocketPilot_AI_$start';
    }
    return 'PocketPilot_AI_${start}_to_$end';
  }
}
