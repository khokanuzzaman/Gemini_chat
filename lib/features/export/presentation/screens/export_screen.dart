import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/export/export_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../category/presentation/providers/category_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final exportNotifier = ref.read(exportProvider.notifier);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Export করুন')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: FutureBuilder<ExportPreviewData>(
          future: exportNotifier.loadPreview(),
          builder: (context, snapshot) {
            final preview = snapshot.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExportPreviewCard(preview: preview),
                const SizedBox(height: 24),
                Text(
                  'সময়কাল বেছে নিন',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExportDateRange.values
                      .map(
                        (range) => FilterChip(
                          label: Text(range.label),
                          selected: exportState.selectedRange == range,
                          onSelected: (_) => exportNotifier.setRange(range),
                        ),
                      )
                      .toList(growable: false),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: exportState.selectedRange == ExportDateRange.custom
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _DateCard(
                                  label: 'শুরু',
                                  date: exportState.customStart,
                                  onTap: () => _pickCustomDate(isStart: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateCard(
                                  label: 'শেষ',
                                  date: exportState.customEnd,
                                  onTap: () => _pickCustomDate(isStart: false),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Category filter',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('সব'),
                      selected: exportState.selectedCategory == null,
                      onSelected: (_) => exportNotifier.setCategory(null),
                    ),
                    ...categories.map((category) {
                      return FilterChip(
                        avatar: Icon(
                          CategoryIcon.getIconData(category.icon),
                          size: 14,
                          color: category.color,
                        ),
                        label: Text(category.name),
                        selected: exportState.selectedCategory == category.name,
                        selectedColor: category.color.withValues(alpha: 0.15),
                        onSelected: (_) => exportNotifier.setCategory(
                          exportState.selectedCategory == category.name
                              ? null
                              : category.name,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'CSV format — Excel, Google Sheets এ খুলবে। তারিখ, বিবরণ, category, পরিমাণ সব থাকবে।',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: exportState.isExporting
                        ? null
                        : exportNotifier.export,
                    icon: exportState.isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded),
                    label: Text(
                      exportState.isExporting
                          ? 'Export হচ্ছে...'
                          : 'Export ও Share করুন',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ),
                if (exportState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    exportState.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'CSV preview',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                _CsvPreviewTable(preview: preview),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final exportState = ref.read(exportProvider);
    final initialDate = isStart
        ? exportState.customStart ?? DateTime.now()
        : exportState.customEnd ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null) {
      return;
    }

    final state = ref.read(exportProvider);
    final start = isStart
        ? pickedDate
        : (state.customStart ??
              DateTime(DateTime.now().year, DateTime.now().month, 1));
    final end = isStart ? (state.customEnd ?? DateTime.now()) : pickedDate;

    if (end.isBefore(start)) {
      ref.read(exportProvider.notifier).setCustomDates(end, start);
      return;
    }

    ref.read(exportProvider.notifier).setCustomDates(start, end);
  }
}

class _ExportPreviewCard extends StatelessWidget {
  const _ExportPreviewCard({required this.preview});

  final ExportPreviewData? preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.table_chart_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: preview == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export preview', style: AppTextStyles.bodySmall),
                        SizedBox(height: 4),
                        Text('Loading...', style: AppTextStyles.titleMedium),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export preview',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${BanglaFormatters.count(preview!.count)}টি expense',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${BanglaFormatters.currency(preview!.totalAmount)} মোট',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Text(
              date == null
                  ? 'তারিখ বাছাই করুন'
                  : BanglaFormatters.fullDate(date!),
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CsvPreviewTable extends StatelessWidget {
  const _CsvPreviewTable({required this.preview});

  final ExportPreviewData? preview;

  @override
  Widget build(BuildContext context) {
    final expenses = preview?.expenses ?? const <ExpenseEntity>[];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surface,
              ),
              columns: const [
                DataColumn(label: Text('তারিখ')),
                DataColumn(label: Text('বিবরণ')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('পরিমাণ')),
              ],
              rows: expenses
                  .take(3)
                  .map((expense) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                        ),
                        DataCell(Text(expense.description)),
                        DataCell(Text(expense.category)),
                        DataCell(Text(expense.amount.toStringAsFixed(2))),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          if (expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Preview দেখানোর মতো expense নেই',
                style: AppTextStyles.bodySmall,
              ),
            ),
          if (expenses.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                '...এবং আরো ${BanglaFormatters.count(expenses.length - 3)}টি',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
