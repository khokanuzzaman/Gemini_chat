import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/expense/domain/entities/expense_entity.dart';
import '../constants/app_strings.dart';
import '../database/models/expense_record_model.dart';
import '../providers/database_providers.dart';
import 'csv_export_service.dart';

enum ExportDateRange {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  allTime,
  custom,
}

extension ExportDateRangeLabel on ExportDateRange {
  String get label => switch (this) {
    ExportDateRange.thisMonth => 'এই মাস',
    ExportDateRange.lastMonth => 'গত মাস',
    ExportDateRange.last3Months => 'গত ৩ মাস',
    ExportDateRange.last6Months => 'গত ৬ মাস',
    ExportDateRange.thisYear => 'এই বছর',
    ExportDateRange.allTime => 'সব সময়',
    ExportDateRange.custom => 'Custom range',
  };
}

class ExportState {
  const ExportState({
    required this.isExporting,
    required this.selectedRange,
    this.error,
    this.customStart,
    this.customEnd,
    this.selectedCategory,
  });

  final bool isExporting;
  final String? error;
  final ExportDateRange selectedRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? selectedCategory;

  ExportState copyWith({
    bool? isExporting,
    String? error,
    bool clearError = false,
    ExportDateRange? selectedRange,
    DateTime? customStart,
    DateTime? customEnd,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      error: clearError ? null : (error ?? this.error),
      selectedRange: selectedRange ?? this.selectedRange,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
    );
  }
}

class ExportPreviewData {
  const ExportPreviewData({
    required this.expenses,
    required this.totalAmount,
    required this.range,
  });

  final List<ExpenseEntity> expenses;
  final double totalAmount;
  final DateTimeRange range;

  int get count => expenses.length;
}

final exportCsvServiceProvider = Provider<CsvExportService>((ref) {
  return const CsvExportService();
});

final exportProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() {
    return const ExportState(
      isExporting: false,
      selectedRange: ExportDateRange.thisMonth,
    );
  }

  void setRange(ExportDateRange range) {
    if (range == ExportDateRange.custom) {
      final now = DateTime.now();
      state = state.copyWith(
        selectedRange: range,
        clearError: true,
        customStart: state.customStart ?? DateTime(now.year, now.month, 1),
        customEnd: state.customEnd ?? now,
      );
      return;
    }

    state = state.copyWith(selectedRange: range, clearError: true);
  }

  void setCustomDates(DateTime start, DateTime end) {
    state = state.copyWith(
      selectedRange: ExportDateRange.custom,
      customStart: _startOfDay(start),
      customEnd: _endOfDay(end),
      clearError: true,
    );
  }

  void setCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
      clearError: true,
    );
  }

  DateTimeRange getDateRange() {
    final now = DateTime.now();
    return switch (state.selectedRange) {
      ExportDateRange.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: _endOfDay(now),
      ),
      ExportDateRange.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(milliseconds: 1)),
      ),
      ExportDateRange.last3Months => DateTimeRange(
        start: DateTime(now.year, now.month - 3, 1),
        end: _endOfDay(now),
      ),
      ExportDateRange.last6Months => DateTimeRange(
        start: DateTime(now.year, now.month - 6, 1),
        end: _endOfDay(now),
      ),
      ExportDateRange.thisYear => DateTimeRange(
        start: DateTime(now.year, 1, 1),
        end: _endOfDay(now),
      ),
      ExportDateRange.allTime => DateTimeRange(
        start: DateTime(2020, 1, 1),
        end: _endOfDay(now),
      ),
      ExportDateRange.custom => DateTimeRange(
        start: _startOfDay(state.customStart ?? now),
        end: _endOfDay(state.customEnd ?? now),
      ),
    };
  }

  Future<ExportPreviewData> loadPreview() async {
    final range = getDateRange();
    final expenses = await _loadExpenses(
      start: range.start,
      end: range.end,
      category: state.selectedCategory,
    );
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return ExportPreviewData(
      expenses: expenses,
      totalAmount: total,
      range: range,
    );
  }

  Future<void> export() async {
    state = state.copyWith(isExporting: true, clearError: true);

    try {
      final range = getDateRange();
      final expenses = await _loadExpenses(
        start: range.start,
        end: range.end,
        category: state.selectedCategory,
      );

      if (expenses.isEmpty) {
        state = state.copyWith(
          isExporting: false,
          error: AppStrings.exportNoExpenses,
        );
        return;
      }

      final fileName = _buildFileName(
        startDate: range.start,
        endDate: range.end,
        category: state.selectedCategory,
      );
      final file = await ref
          .read(exportCsvServiceProvider)
          .exportToCSV(expenses: expenses, fileName: fileName);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: AppStrings.exportShareSubject,
        text:
            '${expenses.length}টি expense — ${DateFormat('dd MMM yyyy').format(range.start)} থেকে ${DateFormat('dd MMM yyyy').format(range.end)}',
      );

      state = state.copyWith(isExporting: false, clearError: true);
    } catch (_) {
      state = state.copyWith(isExporting: false, error: AppStrings.exportError);
    }
  }

  Future<String?> exportExpenses({
    required List<ExpenseEntity> expenses,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    String? fileName,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);

    try {
      final sortedExpenses = [...expenses]
        ..sort((first, second) => second.date.compareTo(first.date));

      if (sortedExpenses.isEmpty) {
        final message = AppStrings.exportNoExpenses;
        state = state.copyWith(isExporting: false, error: message);
        return message;
      }

      final file = await ref
          .read(exportCsvServiceProvider)
          .exportToCSV(
            expenses: sortedExpenses,
            fileName:
                fileName ??
                _buildFileName(
                  startDate: startDate,
                  endDate: endDate,
                  category: category,
                ),
          );

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: AppStrings.exportShareSubject,
        text:
            '${sortedExpenses.length}টি expense — ${DateFormat('dd MMM yyyy').format(startDate)} থেকে ${DateFormat('dd MMM yyyy').format(endDate)}',
      );

      state = state.copyWith(isExporting: false, clearError: true);
      return null;
    } catch (_) {
      final message = AppStrings.exportError;
      state = state.copyWith(isExporting: false, error: message);
      return message;
    }
  }

  Future<List<ExpenseEntity>> _loadExpenses({
    required DateTime start,
    required DateTime end,
    required String? category,
  }) async {
    final localDataSource = ref.read(expenseLocalDataSourceProvider);
    final models = state.selectedRange == ExportDateRange.allTime
        ? await localDataSource.getAllExpenses()
        : await localDataSource.getExpensesByDateRange(start, end);

    var expenses = models.map(_toEntity).toList(growable: false);
    if (category != null) {
      expenses = expenses
          .where((expense) => expense.category == category)
          .toList(growable: false);
    }

    expenses.sort((first, second) => second.date.compareTo(first.date));
    return expenses;
  }

  ExpenseEntity _toEntity(ExpenseRecordModel model) {
    return ExpenseEntity(
      id: model.id,
      amount: model.amount.toDouble(),
      category: model.category,
      description: model.description,
      date: model.date,
      isManual: model.isManual,
    );
  }

  String _buildFileName({
    required DateTime startDate,
    required DateTime endDate,
    required String? category,
  }) {
    final base = ref
        .read(exportCsvServiceProvider)
        .generateFileName(startDate: startDate, endDate: endDate);
    if (category == null || category.trim().isEmpty) {
      return base;
    }
    final safeCategory = category.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return '${base}_$safeCategory';
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
