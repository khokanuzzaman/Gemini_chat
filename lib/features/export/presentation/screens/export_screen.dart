import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/export/export_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/domain/entities/expense_entity.dart';

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

    return AppPageScaffold(
      title: 'ডেটা এক্সপোর্ট',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FutureBuilder<ExportPreviewData>(
          future: exportNotifier.loadPreview(),
          builder: (context, snapshot) {
            final preview = snapshot.data;

            return AppStaggeredList(
              children: [
                _ExportPreviewCard(preview: preview),
                AppCard(
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        padding: EdgeInsets.zero,
                        title: 'এক্সপোর্ট অপশন',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppListTile(
                        leadingIcon: Icons.table_chart_rounded,
                        leadingColor: context.appColors.primary,
                        title: 'CSV এক্সপোর্ট',
                        subtitle: 'সব খরচ CSV ফাইলে ডাউনলোড করুন',
                      ),
                    ],
                  ),
                ),
                AppCard(
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        padding: EdgeInsets.zero,
                        title: 'সময়কাল',
                        subtitle: 'কোন সময়ের ডেটা বের করবেন',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: ExportDateRange.values
                            .map(
                              (range) => AppChip(
                                label: range.label,
                                selected: exportState.selectedRange == range,
                                onTap: () => exportNotifier.setRange(range),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      if (exportState.selectedRange ==
                          ExportDateRange.custom) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _DateCard(
                                label: 'শুরু',
                                date: exportState.customStart,
                                onTap: () => _pickCustomDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _DateCard(
                                label: 'শেষ',
                                date: exportState.customEnd,
                                onTap: () => _pickCustomDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                AppCard(
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        padding: EdgeInsets.zero,
                        title: 'ক্যাটাগরি ফিল্টার',
                        subtitle: 'প্রয়োজনে নির্দিষ্ট ক্যাটাগরি বেছে নিন',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppChip(
                            label: 'সব',
                            selected: exportState.selectedCategory == null,
                            onTap: () => exportNotifier.setCategory(null),
                          ),
                          ...categories.map((category) {
                            return AppChip(
                              label: category.name,
                              icon: CategoryIcon.getIconData(category.icon),
                              color: category.color,
                              selected:
                                  exportState.selectedCategory == category.name,
                              onTap: () => exportNotifier.setCategory(
                                exportState.selectedCategory == category.name
                                    ? null
                                    : category.name,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                AppCard(
                  elevation: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: context.appColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'CSV format Excel বা Google Sheets-এ খুলবে। তারিখ, বিবরণ, ক্যাটাগরি ও পরিমাণ থাকবে।',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                AppActionButton(
                  label: exportState.isExporting
                      ? 'এক্সপোর্ট হচ্ছে...'
                      : 'এক্সপোর্ট করুন',
                  icon: Icons.share_rounded,
                  fullWidth: true,
                  isLoading: exportState.isExporting,
                  onPressed: exportState.isExporting
                      ? null
                      : exportNotifier.export,
                ),
                if (exportState.error != null)
                  AppErrorState(
                    title: 'এক্সপোর্ট করা যায়নি',
                    message: exportState.error,
                    compact: true,
                  ),
                AppCard(
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        padding: EdgeInsets.zero,
                        title: 'CSV প্রিভিউ',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CsvPreviewTable(preview: preview),
                    ],
                  ),
                ),
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
    return AppHeroCard(
      label: 'এক্সপোর্ট প্রিভিউ',
      amount: preview == null ? '...' : BanglaFormatters.count(preview!.count),
      subtitle: preview == null
          ? 'ডেটা লোড হচ্ছে'
          : '${BanglaFormatters.currency(preview!.totalAmount)} মোট খরচ',
      icon: Icons.table_chart_rounded,
      gradient: AppGradients.primary,
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
      borderRadius: const BorderRadius.all(AppRadius.input),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.mutedSurfaceColor,
          borderRadius: const BorderRadius.all(AppRadius.input),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date == null
                  ? 'তারিখ বাছাই করুন'
                  : BanglaFormatters.fullDate(date!),
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
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

    if (preview == null) {
      return const AppLoadingState.card(height: 180);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                context.mutedSurfaceColor,
              ),
              columns: const [
                DataColumn(label: Text('তারিখ')),
                DataColumn(label: Text('বিবরণ')),
                DataColumn(label: Text('ক্যাটাগরি')),
                DataColumn(label: Text('পরিমাণ')),
              ],
              rows: expenses
                  .take(3)
                  .map(
                    (expense) => DataRow(
                      cells: [
                        DataCell(
                          Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                        ),
                        DataCell(Text(expense.description)),
                        DataCell(Text(expense.category)),
                        DataCell(
                          Text(BanglaFormatters.currency(expense.amount)),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Text(
                'প্রিভিউ দেখানোর মতো খরচ নেই',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          if (expenses.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                'আরো ${BanglaFormatters.count(expenses.length - 3)}টি এন্ট্রি আছে',
                style: AppTextStyles.caption.copyWith(
                  color: context.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
