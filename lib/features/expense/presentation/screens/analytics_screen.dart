import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/global_settings_button.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../anomaly/presentation/screens/anomaly_screen.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../prediction/presentation/widgets/prediction_widget.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: AppShellNavigation.analyticsTab.value,
    );
    _tabController.addListener(_handleTabChange);
    AppShellNavigation.analyticsTab.addListener(_handleExternalAnalyticsTab);
  }

  @override
  void dispose() {
    AppShellNavigation.analyticsTab.removeListener(_handleExternalAnalyticsTab);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highSeverityCount = ref.watch(anomalyProvider).highSeverityCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিশ্লেষণ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'বিশ্লেষণ'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('অস্বাভাবিক'),
                  if (highSeverityCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        highSeverityCount > 9
                            ? '9+'
                            : '$highSeverityCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: const [GlobalSettingsButton()],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AnalyticsOverviewTab(),
          AnomalyView(includeTopPadding: false),
        ],
      ),
    );
  }

  void _handleExternalAnalyticsTab() {
    final targetIndex = AppShellNavigation.analyticsTab.value;
    if (!_tabController.indexIsChanging && _tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      AppShellNavigation.analyticsTab.value = _tabController.index;
    }
  }
}

class _AnalyticsOverviewTab extends ConsumerWidget {
  const _AnalyticsOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsControllerProvider);
    final categoryNames = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);

    return analytics.when(
        data: (state) {
          final data = state.data;
          final dayKeys = data.dailyTotals.keys.toList(growable: false);
          final selectedDay = state.selectedDay;
          final selectedExpenses = selectedDay == null
              ? null
              : data.expensesByDay[selectedDay] ?? const <ExpenseEntity>[];
          final totalDays = data.dailyTotals.isEmpty
              ? 1
              : data.dailyTotals.length;
          final dailyAverage = data.totalSpent / totalDays;

          if (data.transactionCount < 1) {
            return const _AnalyticsEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(analyticsControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _MonthSelector(month: state.selectedMonth),
                const SizedBox(height: 16),
                _SummaryRow(
                  totalSpent: data.totalSpent,
                  highestCategory: data.highestCategory,
                  dailyAverage: dailyAverage,
                ),
                const SizedBox(height: 18),
                PredictionWidget(
                  month: state.selectedMonth,
                  currentSpent: data.totalSpent,
                ),
                const SizedBox(height: 18),
                _SpendingTrendChart(
                  dayKeys: dayKeys,
                  totals: data.dailyTotals,
                  selectedDay: selectedDay,
                ),
                const SizedBox(height: 18),
                _CategoryDonutChart(
                  totalSpent: data.totalSpent,
                  categoryTotals: data.thisMonthByCategory,
                ),
                const SizedBox(height: 18),
                _SelectedDayCard(
                  selectedDay: selectedDay,
                  expenses: selectedExpenses,
                ),
                const SizedBox(height: 18),
                _ComparisonSection(
                  categories: categoryNames,
                  thisMonth: data.thisMonthByCategory,
                  lastMonth: data.lastMonthByCategory,
                ),
              ],
            ),
          );
        },
        loading: () => const _AnalyticsLoading(),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'বিশ্লেষণ লোড করা যায়নি\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
      );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(analyticsControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: controller.previousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                BanglaFormatters.monthYear(month),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),
            ),
            IconButton(
              onPressed: controller.nextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalSpent,
    required this.highestCategory,
    required this.dailyAverage,
  });

  final double totalSpent;
  final String highestCategory;
  final double dailyAverage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Total',
            value: BanglaFormatters.currency(totalSpent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(label: 'Highest', value: highestCategory),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Daily avg',
            value: BanglaFormatters.currency(dailyAverage),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _SpendingTrendChart extends ConsumerWidget {
  const _SpendingTrendChart({
    required this.dayKeys,
    required this.totals,
    required this.selectedDay,
  });

  final List<DateTime> dayKeys;
  final Map<DateTime, double> totals;
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxValue = totals.values.fold<double>(
      0,
      (previousValue, element) =>
          element > previousValue ? element : previousValue,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spending trend', style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'শেষ ৭ দিনের smooth view',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue == 0 ? 100 : maxValue * 1.3,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: ChartTheme.gridLine(context),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.lineBarSpots == null ||
                          response!.lineBarSpots!.isEmpty) {
                        return;
                      }
                      ref
                          .read(analyticsControllerProvider.notifier)
                          .selectDay(
                            dayKeys[response.lineBarSpots!.first.x.toInt()],
                          );
                    },
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            BanglaFormatters.count(value.round()),
                            style: AppTextStyles.caption,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dayKeys.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${dayKeys[index].day}',
                              style: AppTextStyles.caption,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.24),
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final isSelected =
                              selectedDay != null &&
                              dayKeys[index].year == selectedDay!.year &&
                              dayKeys[index].month == selectedDay!.month &&
                              dayKeys[index].day == selectedDay!.day;
                          return FlDotCirclePainter(
                            radius: isSelected ? 6 : 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Theme.of(context).cardColor,
                          );
                        },
                      ),
                      spots: List.generate(dayKeys.length, (index) {
                        final day = dayKeys[index];
                        return FlSpot(index.toDouble(), totals[day] ?? 0);
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDonutChart extends StatefulWidget {
  const _CategoryDonutChart({
    required this.totalSpent,
    required this.categoryTotals,
  });

  final double totalSpent;
  final Map<String, double> categoryTotals;

  @override
  State<_CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<_CategoryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.categoryTotals.entries.toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category breakdown', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Text(
                'বিশ্লেষণের জন্য data দরকার',
                style: AppTextStyles.bodyMedium,
              )
            else ...[
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 54,
                        centerSpaceColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        sectionsSpace: 4,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              _touchedIndex =
                                  response
                                      ?.touchedSection
                                      ?.touchedSectionIndex ??
                                  -1;
                            });
                          },
                        ),
                        sections: entries
                            .asMap()
                            .entries
                            .map((entry) {
                              final meta = resolveExpenseCategory(
                                entry.value.key,
                              );
                              final isTouched = entry.key == _touchedIndex;
                              return PieChartSectionData(
                                color: meta.color,
                                value: entry.value.value,
                                radius: isTouched ? 62 : 54,
                                title: '',
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('মোট', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Text(
                          BanglaFormatters.currency(widget.totalSpent),
                          style: AppTextStyles.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map((entry) {
                final meta = resolveExpenseCategory(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: meta.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.key, style: AppTextStyles.bodyMedium),
                      ),
                      Text(
                        BanglaFormatters.currency(entry.value),
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.selectedDay, required this.expenses});

  final DateTime? selectedDay;
  final List<ExpenseEntity>? expenses;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedDay == null
                  ? 'দিনের খরচ'
                  : BanglaFormatters.fullDate(selectedDay!),
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 12),
            if (selectedDay == null)
              const Text(
                'চার্ট থেকে একটি দিন বেছে নিন',
                style: AppTextStyles.bodyMedium,
              )
            else if (expenses == null || expenses!.isEmpty)
              const Text(
                'সেই দিনে কোনো খরচ নেই',
                style: AppTextStyles.bodyMedium,
              )
            else
              ...expenses!.map((expense) {
                final meta = resolveExpenseCategory(expense.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(meta.icon, color: meta.color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          expense.description,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        BanglaFormatters.currency(expense.amount),
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.categories,
    required this.thisMonth,
    required this.lastMonth,
  });

  final List<String> categories;
  final Map<String, double> thisMonth;
  final Map<String, double> lastMonth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Month comparison', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final current = thisMonth[category] ?? 0;
              final previous = lastMonth[category] ?? 0;
              final difference = current - previous;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Text(
                          difference == 0
                              ? 'সমান'
                              : '${difference.isNegative ? '↓' : '↑'} ${BanglaFormatters.currency(difference.abs())}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: difference > 0
                                ? AppColors.error
                                : difference < 0
                                ? AppColors.success
                                : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: ChartTheme.barBackground(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _ratio(previous, current, previous),
                              child: Container(color: AppColors.grey400),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: ChartTheme.barBackground(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _ratio(current, current, previous),
                              child: Container(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'গত মাস ${BanglaFormatters.currency(previous)}',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'এই মাস ${BanglaFormatters.currency(current)}',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _ratio(double value, double current, double previous) {
    final max = current > previous ? current : previous;
    if (max <= 0) {
      return 0;
    }
    return (value / max).clamp(0, 1);
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        ShimmerBox(height: 68),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 90)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 90)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 90)),
          ],
        ),
        SizedBox(height: 18),
        ShimmerBox(height: 260),
        SizedBox(height: 18),
        ShimmerBox(height: 320),
        SizedBox(height: 18),
        ShimmerBox(height: 180),
      ],
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.mutedSurfaceColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: 40,
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'বিশ্লেষণের জন্য data দরকার',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'কমপক্ষে ৫টি খরচ যোগ করুন',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
