part of '../../screens/analytics_screen.dart';

class _AnalyticsScreenContent extends ConsumerStatefulWidget {
  const _AnalyticsScreenContent();

  @override
  ConsumerState<_AnalyticsScreenContent> createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<_AnalyticsScreenContent> {
  late int _selectedTabIndex;

  bool get _isAnomalyTabSelected => _selectedTabIndex == 4;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = AppShellNavigation.analyticsTab.value;
    AppShellNavigation.analyticsTab.addListener(_handleExternalAnalyticsTab);
    AppShellNavigation.selectedTab.addListener(_handleShellTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerPredictionLoadIfVisible();
    });
  }

  @override
  void dispose() {
    AppShellNavigation.analyticsTab.removeListener(_handleExternalAnalyticsTab);
    AppShellNavigation.selectedTab.removeListener(_handleShellTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsControllerProvider);
    final anomalyState = ref.watch(anomalyProvider);

    return AppPageScaffold(
      title: 'বিশ্লেষণ',
      showBackButton: false,
      showOfflineBanner: false,
      body: analytics.when(
        data: (state) {
          final tabs = _buildTabs();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: AppFadeSlideIn(
                  child: _MonthNavigator(
                    month: state.selectedMonth,
                    enabled: !_isAnomalyTabSelected,
                    disabledTooltipMessage: 'অ্যানোমালি ট্যাবে মাস নির্বাচন প্রযোজ্য নয়',
                    onPrevious: () => ref
                        .read(analyticsControllerProvider.notifier)
                        .previousMonth(),
                    onNext: () => ref
                        .read(analyticsControllerProvider.notifier)
                        .nextMonth(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: AppSegmentedTabs(
                  tabs: tabs.map((tab) => tab.label).toList(growable: false),
                  selectedIndex: _selectedTabIndex,
                  compact: tabs.length >= 4,
                  onChanged: _selectDisplayTab,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.standard,
                  switchOutCurve: AppMotion.standard,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedTabIndex),
                    child: _buildSelectedTab(
                      context: context,
                      state: state,
                      anomalyState: anomalyState,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: _buildLoadingState,
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(analyticsControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  List<_AnalyticsTabItem> _buildTabs() {
    return const [
      _AnalyticsTabItem(label: 'সারাংশ', displayIndex: 0),
      _AnalyticsTabItem(label: 'ক্যাটাগরি', displayIndex: 1),
      _AnalyticsTabItem(label: 'ওয়ালেট', displayIndex: 2),
      _AnalyticsTabItem(label: 'আয়', displayIndex: 3),
      _AnalyticsTabItem(label: 'অ্যানোমালি', displayIndex: 4),
    ];
  }

  Widget _buildSelectedTab({
    required BuildContext context,
    required AnalyticsState state,
    required AnomalyState anomalyState,
  }) {
    return switch (_selectedTabIndex) {
      0 => _buildScrollableTab(
        onRefresh: () =>
            ref.read(analyticsControllerProvider.notifier).refresh(),
        child: _SummaryTabContent(state: state),
      ),
      1 => _buildScrollableTab(
        onRefresh: () =>
            ref.read(analyticsControllerProvider.notifier).refresh(),
        child: _CategoryTabContent(state: state),
      ),
      2 => _buildScrollableTab(
        onRefresh: () =>
            ref.read(analyticsControllerProvider.notifier).refresh(),
        child: _WalletTabContent(selectedMonth: state.selectedMonth),
      ),
      3 => _buildScrollableTab(
        onRefresh: _refreshIncomeTab,
        child: _IncomeTabContent(selectedMonth: state.selectedMonth),
      ),
      4 => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: AnomalyView(includeTopPadding: false),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildScrollableTab({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.appColors.primary,
      backgroundColor: context.cardBackgroundColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: child,
      ),
    );
  }

  Future<void> _refreshIncomeTab() async {
    await ref.read(analyticsControllerProvider.notifier).refresh();
    await ref.read(incomeListControllerProvider.notifier).refresh();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            0,
          ),
          child: AppLoadingState.card(height: 56),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            0,
          ),
          child: AppLoadingState.card(height: 56),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
            ),
            child: AppLoadingState.list(),
          ),
        ),
      ],
    );
  }

  void _selectDisplayTab(int displayIndex) {
    if (_selectedTabIndex == displayIndex) {
      return;
    }

    setState(() {
      _selectedTabIndex = displayIndex;
    });
    AppShellNavigation.analyticsTab.value = displayIndex;
    _triggerPredictionLoadIfVisible();
  }

  void _handleExternalAnalyticsTab() {
    final targetDisplayIndex = AppShellNavigation.analyticsTab.value;
    if (targetDisplayIndex == _selectedTabIndex) {
      return;
    }

    setState(() {
      _selectedTabIndex = targetDisplayIndex;
    });
    _triggerPredictionLoadIfVisible();
  }

  void _handleShellTabChange() {
    _triggerPredictionLoadIfVisible();
  }

  void _triggerPredictionLoadIfVisible() {
    if (!mounted) {
      return;
    }
    final isAnalyticsScreen = AppShellNavigation.selectedTab.value == 3;
    final isSummaryTab = _selectedTabIndex == 0;
    if (!isAnalyticsScreen || !isSummaryTab) {
      return;
    }
    ref.read(predictionProvider.notifier).loadPrediction();
  }
}

class _AnalyticsTabItem {
  const _AnalyticsTabItem({required this.label, required this.displayIndex});

  final String label;
  final int displayIndex;
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.enabled,
    required this.disabledTooltipMessage,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool enabled;
  final String disabledTooltipMessage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final navigator = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: enabled ? onPrevious : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: context.secondaryTextColor,
            ),
          ),
          Expanded(
            child: Text(
              BanglaFormatters.monthYear(month),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? onNext : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );

    final wrappedNavigator = IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: AppMotion.fast,
        child: navigator,
      ),
    );

    if (enabled) {
      return wrappedNavigator;
    }

    return Tooltip(
      message: disabledTooltipMessage,
      child: wrappedNavigator,
    );
  }
}

class _SummaryTabContent extends ConsumerWidget {
  const _SummaryTabContent({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = state.data;
    final dayKeys = data.dailyTotals.keys.toList(growable: false);
    final selectedDay = state.selectedDay;
    final selectedExpenses = selectedDay == null
        ? null
        : data.expensesByDay[selectedDay] ?? const <ExpenseEntity>[];
    final totalDays = data.dailyTotals.isEmpty ? 1 : data.dailyTotals.length;
    final dailyAverage = data.totalSpent / totalDays;
    final lastMonthTotal = data.lastMonthByCategory.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );

    if (data.transactionCount < 1) {
      return const AppEmptyState(
        icon: Icons.insert_chart_outlined_rounded,
        title: 'বিশ্লেষণের জন্য ডেটা নেই',
        subtitle: 'কমপক্ষে ৫টি খরচ যোগ করলে বিশ্লেষণ দেখা যাবে',
      );
    }

    final statTrend = lastMonthTotal > 0
        ? StatTrend(
            percentage:
                ((data.totalSpent - lastMonthTotal) / lastMonthTotal) * 100,
            isPositive: data.totalSpent <= lastMonthTotal,
          )
        : null;

    return AppStaggeredList(
      children: [
        if (_isCurrentMonth(state.selectedMonth)) ...[
          const PredictionCard(),
          const SizedBox(height: AppSpacing.md),
        ],
        AppFadeSlideIn(
          child: Row(
            children: [
              Expanded(
                child: AppStatCard(
                  label: 'মোট খরচ',
                  value: BanglaFormatters.currency(data.totalSpent),
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.error,
                  valueColor: context.expenseColor,
                  trend: statTrend,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppStatCard(
                  label: 'লেনদেন',
                  value: BanglaFormatters.count(data.transactionCount),
                  icon: Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppStatCard(
                  label: 'গড়/দিন',
                  value: BanglaFormatters.currency(dailyAverage),
                  icon: Icons.show_chart_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _SpendingTrendCard(
          dayKeys: dayKeys,
          totals: data.dailyTotals,
          selectedDay: selectedDay,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _SelectedDayExpenseCard(
          selectedDay: selectedDay,
          expenses: selectedExpenses,
        ),
      ],
    );
  }
}

class _SpendingTrendCard extends ConsumerWidget {
  const _SpendingTrendCard({
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
      (maxValue, value) => value > maxValue ? value : maxValue,
    );

    return AppFadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: AppCard(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'দৈনিক খরচ',
              subtitle: 'নির্বাচিত মাসের প্রতিদিনের খরচ দেখুন',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue == 0 ? 100 : maxValue * 1.25,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.borderColor.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          ChartTheme.tooltipBackground(context),
                      getTooltipItems: (spots) {
                        return spots
                            .map((spot) {
                              final day = dayKeys[spot.x.toInt()];
                              return LineTooltipItem(
                                '${BanglaFormatters.dayMonth(day)}\n${BanglaFormatters.currency(spot.y)}',
                                AppTextStyles.bodySmall.copyWith(
                                  color: ChartTheme.tooltipText(context),
                                ),
                              );
                            })
                            .toList(growable: false);
                      },
                    ),
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
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            BanglaFormatters.count(value.round()),
                            style: AppTextStyles.caption.copyWith(
                              color: context.secondaryTextColor,
                            ),
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
                              BanglaFormatters.count(dayKeys[index].day),
                              style: AppTextStyles.caption.copyWith(
                                color: context.secondaryTextColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: context.appColors.primary,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            context.appColors.primary.withValues(alpha: 0.22),
                            context.appColors.primary.withValues(alpha: 0.02),
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
                            color: context.appColors.primary,
                            strokeWidth: 2,
                            strokeColor: context.cardBackgroundColor,
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

class _SelectedDayExpenseCard extends StatelessWidget {
  const _SelectedDayExpenseCard({
    required this.selectedDay,
    required this.expenses,
  });

  final DateTime? selectedDay;
  final List<ExpenseEntity>? expenses;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      delay: const Duration(milliseconds: 150),
      child: AppCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: selectedDay == null
                  ? 'দিনভিত্তিক বিস্তারিত'
                  : BanglaFormatters.fullDate(selectedDay!),
              subtitle: selectedDay == null
                  ? 'চার্ট থেকে একটি দিন বেছে নিন'
                  : 'নির্বাচিত দিনের সব খরচ',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            if (selectedDay == null)
              Text(
                'চার্টে ট্যাপ করলে সেই দিনের খরচ এখানে দেখা যাবে।',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
              )
            else if (expenses == null || expenses!.isEmpty)
              Text(
                'সেই দিনে কোনো খরচ নেই।',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
              )
            else ...[
              for (var i = 0; i < expenses!.length; i++) ...[
                _SelectedExpenseTile(expense: expenses![i]),
                if (i != expenses!.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedExpenseTile extends StatelessWidget {
  const _SelectedExpenseTile({required this.expense});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context) {
    final meta = resolveExpenseCategory(expense.category);
    return AppListTile(
      leadingEmoji: _categoryEmoji(expense.category),
      leadingColor: meta.color,
      title: expense.description,
      subtitle:
          '${_categoryDisplayName(expense.category)} · ${BanglaFormatters.time(expense.date)}',
      trailingAmount: expense.amount,
      trailingAmountIsExpense: true,
      dense: true,
      padding: EdgeInsets.zero,
    );
  }
}

class _CategoryTabContent extends StatelessWidget {
  const _CategoryTabContent({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final totals =
        state.data.thisMonthByCategory.entries
            .where((entry) => entry.value > 0)
            .toList(growable: false)
          ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = state.data.totalSpent;
    final comparisonCategories = {
      ...state.data.thisMonthByCategory.keys,
      ...state.data.lastMonthByCategory.keys,
    }.toList(growable: false)..sort();

    if (totals.isEmpty) {
      return const AppEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: 'ক্যাটাগরি বিশ্লেষণ নেই',
        subtitle: 'নির্বাচিত মাসে কোনো খরচ পাওয়া যায়নি',
      );
    }

    return AppStaggeredList(
      children: [
        _CategoryBreakdownChartCard(
          totalSpent: totalSpent,
          categoryTotals: totals,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _CategoryBreakdownListCard(
          totalSpent: totalSpent,
          categoryTotals: totals,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _ComparisonCard(
          categories: comparisonCategories,
          thisMonth: state.data.thisMonthByCategory,
          lastMonth: state.data.lastMonthByCategory,
        ),
      ],
    );
  }
}

class _CategoryBreakdownChartCard extends StatefulWidget {
  const _CategoryBreakdownChartCard({
    required this.totalSpent,
    required this.categoryTotals,
  });

  final double totalSpent;
  final List<MapEntry<String, double>> categoryTotals;

  @override
  State<_CategoryBreakdownChartCard> createState() =>
      _CategoryBreakdownChartCardState();
}

class _CategoryBreakdownChartCardState
    extends State<_CategoryBreakdownChartCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: AppCard(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'ক্যাটাগরি অনুযায়ী খরচ',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 54,
                      centerSpaceColor: context.cardBackgroundColor,
                      sectionsSpace: 4,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedIndex =
                                response?.touchedSection?.touchedSectionIndex ??
                                -1;
                          });
                        },
                      ),
                      sections: widget.categoryTotals
                          .asMap()
                          .entries
                          .map((entry) {
                            final meta = resolveExpenseCategory(
                              entry.value.key,
                            );
                            final isTouched = entry.key == _touchedIndex;
                            final percentage = widget.totalSpent == 0
                                ? 0
                                : (entry.value.value / widget.totalSpent) * 100;
                            return PieChartSectionData(
                              color: meta.color,
                              value: entry.value.value,
                              radius: isTouched ? 64 : 56,
                              title: percentage >= 12
                                  ? '${percentage.toStringAsFixed(0)}%'
                                  : '',
                              titleStyle: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'মোট',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        BanglaFormatters.currency(widget.totalSpent),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: context.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _CategoryBreakdownListCard extends StatelessWidget {
  const _CategoryBreakdownListCard({
    required this.totalSpent,
    required this.categoryTotals,
  });

  final double totalSpent;
  final List<MapEntry<String, double>> categoryTotals;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: AppCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'ক্যাটাগরি তালিকা',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < categoryTotals.length; i++) ...[
              _CategoryProgressRow(
                entry: categoryTotals[i],
                totalSpent: totalSpent,
              ),
              if (i != categoryTotals.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({required this.entry, required this.totalSpent});

  final MapEntry<String, double> entry;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final meta = resolveExpenseCategory(entry.key);
    final percentage = totalSpent <= 0 ? 0.0 : entry.value / totalSpent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _categoryEmoji(entry.key),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryDisplayName(entry.key),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    BanglaFormatters.currency(entry.value),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.chipLabel.copyWith(color: meta.color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(value: percentage, color: meta.color, height: 6),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.categories,
    required this.thisMonth,
    required this.lastMonth,
  });

  final List<String> categories;
  final Map<String, double> thisMonth;
  final Map<String, double> lastMonth;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      delay: const Duration(milliseconds: 260),
      child: AppCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'গত মাসের তুলনা',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final category in categories) ...[
              _ComparisonRow(
                category: category,
                current: thisMonth[category] ?? 0,
                previous: lastMonth[category] ?? 0,
              ),
              if (category != categories.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.category,
    required this.current,
    required this.previous,
  });

  final String category;
  final double current;
  final double previous;

  @override
  Widget build(BuildContext context) {
    final difference = current - previous;
    final changeColor = difference > 0
        ? AppColors.error
        : difference < 0
        ? AppColors.success
        : context.secondaryTextColor;
    final maxValue = math.max(current, previous).toDouble();
    final currentRatio = maxValue <= 0 ? 0.0 : current / maxValue;
    final previousRatio = maxValue <= 0 ? 0.0 : previous / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _categoryDisplayName(category),
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            Text(
              difference == 0
                  ? 'সমান'
                  : '${difference.isNegative ? '↓' : '↑'} ${BanglaFormatters.currency(difference.abs())}',
              style: AppTextStyles.bodySmall.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppProgressBar(
                value: previousRatio,
                color: AppColors.grey400,
                label: 'গত মাস',
                showLabel: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppProgressBar(
                value: currentRatio,
                color: context.appColors.primary,
                label: 'এই মাস',
                showLabel: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletTabContent extends ConsumerWidget {
  const _WalletTabContent({required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(
      walletBreakdownForMonthProvider(selectedMonth),
    );
    final walletsAsync = ref.watch(walletProvider);

    return breakdownAsync.when(
      data: (breakdown) {
        final activeBreakdown = Map<int, double>.fromEntries(
          breakdown.entries.where((entry) => entry.value > 0),
        );

        if (activeBreakdown.isEmpty) {
          return const AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'ওয়ালেট বিশ্লেষণ নেই',
            subtitle: 'নির্বাচিত মাসে কোনো ওয়ালেট খরচ পাওয়া যায়নি',
          );
        }

        final wallets = walletsAsync.valueOrNull ?? const <WalletEntity>[];
        final walletLookup = <int, WalletEntity>{
          for (final wallet in wallets) wallet.id: wallet,
        };
        final sortedEntries = activeBreakdown.entries.toList()
          ..sort((first, second) => second.value.compareTo(first.value));
        final totalSpent = sortedEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.value,
        );

        return AppStaggeredList(
          children: [
            _WalletBreakdownChartCard(
              totalSpent: totalSpent,
              entries: sortedEntries,
              walletLookup: walletLookup,
            ),
            const SizedBox(height: AppSpacing.cardGap),
            AppFadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: AppCard(
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: 'ওয়ালেট অনুযায়ী খরচ',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < sortedEntries.length; i++) ...[
                      _WalletProgressRow(
                        entry: sortedEntries[i],
                        totalSpent: totalSpent,
                        wallet: walletLookup[sortedEntries[i].key],
                      ),
                      if (i != sortedEntries.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoadingState.list(),
      error: (error, _) => AppErrorState(message: error.toString()),
    );
  }
}

class _WalletBreakdownChartCard extends StatelessWidget {
  const _WalletBreakdownChartCard({
    required this.totalSpent,
    required this.entries,
    required this.walletLookup,
  });

  final double totalSpent;
  final List<MapEntry<int, double>> entries;
  final Map<int, WalletEntity> walletLookup;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: AppCard(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'ওয়ালেট অনুযায়ী খরচ',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 54,
                      centerSpaceColor: context.cardBackgroundColor,
                      sectionsSpace: 4,
                      sections: entries
                          .map((entry) {
                            final wallet = walletLookup[entry.key];
                            final percentage = totalSpent == 0
                                ? 0
                                : (entry.value / totalSpent) * 100;
                            final color = _walletBaseColor(wallet);
                            return PieChartSectionData(
                              color: color,
                              value: entry.value,
                              radius: 58,
                              title: percentage >= 12
                                  ? '${percentage.toStringAsFixed(0)}%'
                                  : '',
                              titleStyle: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'মোট',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        BanglaFormatters.currency(totalSpent),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: context.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _WalletProgressRow extends StatelessWidget {
  const _WalletProgressRow({
    required this.entry,
    required this.totalSpent,
    required this.wallet,
  });

  final MapEntry<int, double> entry;
  final double totalSpent;
  final WalletEntity? wallet;

  @override
  Widget build(BuildContext context) {
    final percentage = totalSpent <= 0 ? 0.0 : entry.value / totalSpent;
    final baseColor = _walletBaseColor(wallet);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: _walletGradient(wallet),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(wallet?.emoji ?? '👛'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet?.name ?? 'ওয়ালেট ${entry.key}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    BanglaFormatters.currency(entry.value),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.chipLabel.copyWith(color: baseColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(value: percentage, color: baseColor, height: 6),
      ],
    );
  }
}

class _IncomeTabContent extends ConsumerWidget {
  const _IncomeTabContent({required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeState = ref.watch(incomeListControllerProvider);
    ref.watch(expenseRefreshTokenProvider);

    return incomeState.when(
      data: (allIncomes) {
        return FutureBuilder<List<ExpenseEntity>>(
          future: ref.read(expenseRepositoryProvider).getAllExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppLoadingState.list();
            }
            if (snapshot.hasError) {
              return AppErrorState(message: '${snapshot.error}');
            }

            final bundle = _IncomeAnalyticsBundle.fromData(
              month: selectedMonth,
              allIncomes: allIncomes,
              allExpenses: snapshot.data ?? const <ExpenseEntity>[],
            );

            if (bundle.allIncomes.isEmpty) {
              return const AppEmptyState(
                icon: Icons.trending_up_rounded,
                title: 'কোনো আয়ের ডেটা নেই',
                subtitle: 'আয় যোগ করলে এখানে উৎসভিত্তিক বিশ্লেষণ দেখা যাবে',
              );
            }

            return AppStaggeredList(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'মোট আয়',
                        value: BanglaFormatters.currency(bundle.totalIncome),
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.success,
                        valueColor: context.incomeColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppStatCard(
                        label: 'লেনদেন',
                        value: BanglaFormatters.count(
                          bundle.filteredIncomes.length,
                        ),
                        icon: Icons.receipt_long_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppStatCard(
                        label: 'গড়/দিন',
                        value: BanglaFormatters.currency(bundle.dailyAverage),
                        icon: Icons.show_chart_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.cardGap),
                if (bundle.sourceTotals.isNotEmpty)
                  _IncomeSourceBreakdownCard(bundle: bundle),
                if (bundle.sourceTotals.isNotEmpty)
                  const SizedBox(height: AppSpacing.cardGap),
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'নিয়মিত',
                        value: BanglaFormatters.currency(bundle.recurringTotal),
                        icon: Icons.repeat_rounded,
                        valueColor: context.incomeColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppStatCard(
                        label: 'এককালীন',
                        value: BanglaFormatters.currency(bundle.oneTimeTotal),
                        icon: Icons.flash_on_rounded,
                        valueColor: context.primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.cardGap),
                _SavingsRateTrendCard(bundle: bundle),
                const SizedBox(height: AppSpacing.cardGap),
                _IncomeVsExpenseChartCard(bundle: bundle),
              ],
            );
          },
        );
      },
      loading: () => const AppLoadingState.list(),
      error: (error, _) => AppErrorState(message: error.toString()),
    );
  }
}

class _IncomeAnalyticsBundle {
  const _IncomeAnalyticsBundle({
    required this.allIncomes,
    required this.filteredIncomes,
    required this.totalIncome,
    required this.dailyAverage,
    required this.recurringTotal,
    required this.oneTimeTotal,
    required this.sourceTotals,
    required this.monthlyPoints,
  });

  final List<IncomeEntity> allIncomes;
  final List<IncomeEntity> filteredIncomes;
  final double totalIncome;
  final double dailyAverage;
  final double recurringTotal;
  final double oneTimeTotal;
  final Map<String, double> sourceTotals;
  final List<_MonthlyIncomePoint> monthlyPoints;

  factory _IncomeAnalyticsBundle.fromData({
    required DateTime month,
    required List<IncomeEntity> allIncomes,
    required List<ExpenseEntity> allExpenses,
  }) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(
      month.year,
      month.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    final filteredIncomes = allIncomes
        .where(
          (income) =>
              !income.date.isBefore(monthStart) &&
              !income.date.isAfter(monthEnd),
        )
        .toList(growable: false);

    final totalIncome = filteredIncomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );
    final daysCount = filteredIncomes
        .map(
          (income) =>
              DateTime(income.date.year, income.date.month, income.date.day),
        )
        .toSet()
        .length;
    final dailyAverage = totalIncome / (daysCount == 0 ? 1 : daysCount);
    final recurringTotal = filteredIncomes
        .where((income) => income.isRecurring)
        .fold<double>(0, (sum, income) => sum + income.amount);
    final oneTimeTotal = totalIncome - recurringTotal;

    final sourceTotals = <String, double>{};
    for (final income in filteredIncomes) {
      sourceTotals.update(
        income.source,
        (value) => value + income.amount,
        ifAbsent: () => income.amount,
      );
    }

    final monthlyPoints = <_MonthlyIncomePoint>[];
    for (var offset = 5; offset >= 0; offset--) {
      final targetMonth = DateTime(month.year, month.month - offset, 1);
      final targetMonthEnd = DateTime(
        targetMonth.year,
        targetMonth.month + 1,
        1,
      ).subtract(const Duration(milliseconds: 1));
      final incomeTotal = allIncomes
          .where(
            (income) =>
                !income.date.isBefore(targetMonth) &&
                !income.date.isAfter(targetMonthEnd),
          )
          .fold<double>(0, (sum, income) => sum + income.amount);
      final expenseTotal = allExpenses
          .where(
            (expense) =>
                !expense.date.isBefore(targetMonth) &&
                !expense.date.isAfter(targetMonthEnd),
          )
          .fold<double>(0, (sum, expense) => sum + expense.amount);
      final savingsRate = incomeTotal <= 0
          ? 0.0
          : ((incomeTotal - expenseTotal) / incomeTotal) * 100;

      monthlyPoints.add(
        _MonthlyIncomePoint(
          month: targetMonth,
          income: incomeTotal,
          expense: expenseTotal,
          savingsRate: savingsRate,
        ),
      );
    }

    return _IncomeAnalyticsBundle(
      allIncomes: allIncomes,
      filteredIncomes: filteredIncomes,
      totalIncome: totalIncome,
      dailyAverage: dailyAverage,
      recurringTotal: recurringTotal,
      oneTimeTotal: oneTimeTotal,
      sourceTotals: sourceTotals,
      monthlyPoints: monthlyPoints,
    );
  }
}

class _MonthlyIncomePoint {
  const _MonthlyIncomePoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.savingsRate,
  });

  final DateTime month;
  final double income;
  final double expense;
  final double savingsRate;
}

class _IncomeSourceBreakdownCard extends StatelessWidget {
  const _IncomeSourceBreakdownCard({required this.bundle});

  final _IncomeAnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final entries = bundle.sourceTotals.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'উৎস অনুযায়ী আয়',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < entries.length; i++) ...[
            _IncomeSourceRow(entry: entries[i], total: bundle.totalIncome),
            if (i != entries.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _IncomeSourceRow extends StatelessWidget {
  const _IncomeSourceRow({required this.entry, required this.total});

  final MapEntry<String, double> entry;
  final double total;

  @override
  Widget build(BuildContext context) {
    final source = findIncomeSourceByName(entry.key);
    final percentage = total <= 0 ? 0.0 : entry.value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(source?.emoji ?? '💰'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source?.banglaLabel ?? entry.key,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    BanglaFormatters.currency(entry.value),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.chipLabel.copyWith(color: AppColors.success),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(value: percentage, color: AppColors.success, height: 6),
      ],
    );
  }
}

class _SavingsRateTrendCard extends StatelessWidget {
  const _SavingsRateTrendCard({required this.bundle});

  final _IncomeAnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final rates = bundle.monthlyPoints
        .map((point) => point.savingsRate)
        .toList();
    var minRate = 0.0;
    var maxRate = 20.0;
    for (final rate in rates) {
      minRate = math.min(minRate, rate);
      maxRate = math.max(maxRate, rate);
    }

    return AppCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'সঞ্চয়ের হার (গত ৬ মাস)',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: minRate - 10,
                maxY: maxRate + 10,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: context.borderColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 20,
                      color: context.borderColor,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ],
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        ChartTheme.tooltipBackground(context),
                    getTooltipItems: (spots) {
                      return spots
                          .map((spot) {
                            final point = bundle.monthlyPoints[spot.x.toInt()];
                            return LineTooltipItem(
                              '${_monthLabel(point.month)}\n${spot.y.toStringAsFixed(0)}%',
                              AppTextStyles.bodySmall.copyWith(
                                color: ChartTheme.tooltipText(context),
                              ),
                            );
                          })
                          .toList(growable: false);
                    },
                  ),
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= bundle.monthlyPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthLabel(bundle.monthlyPoints[index].month),
                            style: AppTextStyles.caption.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.2),
                          AppColors.success.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.success,
                          strokeWidth: 2,
                          strokeColor: context.cardBackgroundColor,
                        );
                      },
                    ),
                    spots: List.generate(bundle.monthlyPoints.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        bundle.monthlyPoints[index].savingsRate,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeVsExpenseChartCard extends StatelessWidget {
  const _IncomeVsExpenseChartCard({required this.bundle});

  final _IncomeAnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final maxValue = bundle.monthlyPoints.fold<double>(
      0,
      (maxValue, point) =>
          math.max(maxValue, math.max(point.income, point.expense)),
    );

    return AppCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'আয় বনাম খরচ',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              AppChip(label: 'আয়', color: AppColors.success),
              AppChip(label: 'খরচ', color: AppColors.error),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: maxValue == 0 ? 100 : maxValue * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: context.borderColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        ChartTheme.tooltipBackground(context),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = bundle.monthlyPoints[group.x.toInt()];
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${_monthLabel(point.month)}\n${isIncome ? 'আয়' : 'খরচ'}: ${BanglaFormatters.currency(rod.toY)}',
                        AppTextStyles.bodySmall.copyWith(
                          color: ChartTheme.tooltipText(context),
                        ),
                      );
                    },
                  ),
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
                      getTitlesWidget: (value, meta) => Text(
                        BanglaFormatters.count(value.round()),
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= bundle.monthlyPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthLabel(bundle.monthlyPoints[index].month),
                            style: AppTextStyles.caption.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(bundle.monthlyPoints.length, (index) {
                  final point = bundle.monthlyPoints[index];
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: point.income,
                        width: 10,
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: point.expense,
                        width: 10,
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(DateTime month) {
  final label = BanglaFormatters.monthYear(month).split(' ');
  return label.isEmpty ? BanglaFormatters.count(month.month) : label.first;
}

bool _isCurrentMonth(DateTime month) {
  final now = DateTime.now();
  return month.year == now.year && month.month == now.month;
}

Color _walletBaseColor(WalletEntity? wallet) {
  return switch (wallet?.type) {
    WalletType.bkash => AppColors.primary,
    WalletType.nagad => AppColors.success,
    WalletType.rocket => AppColors.warning,
    WalletType.bank => AppColors.food,
    WalletType.card => AppColors.shopping,
    WalletType.cash => AppColors.bill,
    _ => AppColors.other,
  };
}

Gradient _walletGradient(WalletEntity? wallet) {
  return switch (wallet?.type) {
    WalletType.bkash => AppGradients.walletBlue,
    WalletType.nagad => AppGradients.walletTeal,
    WalletType.rocket => AppGradients.walletOrange,
    WalletType.bank => AppGradients.walletPurple,
    WalletType.card => AppGradients.walletBlue,
    WalletType.cash => AppGradients.walletTeal,
    _ => AppGradients.surfaceLight,
  };
}

String _categoryEmoji(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
    case 'খাবার':
      return '🍽️';
    case 'transport':
    case 'যাতায়াত':
      return '🛺';
    case 'shopping':
    case 'কেনাকাটা':
      return '🛍️';
    case 'healthcare':
    case 'স্বাস্থ্য':
      return '🩺';
    case 'bill':
    case 'bills':
    case 'বিল':
      return '💡';
    case 'entertainment':
    case 'বিনোদন':
      return '🎬';
    case 'education':
    case 'শিক্ষা':
      return '📚';
    case 'travel':
    case 'ভ্রমণ':
      return '✈️';
    case 'rent':
    case 'ভাড়া':
      return '🏠';
    case 'other':
    case 'অন্যান্য':
      return '🧾';
    default:
      return '💸';
  }
}

String _categoryDisplayName(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
      return 'খাবার';
    case 'transport':
      return 'যাতায়াত';
    case 'shopping':
      return 'কেনাকাটা';
    case 'healthcare':
      return 'স্বাস্থ্য';
    case 'bill':
    case 'bills':
      return 'বিল';
    case 'entertainment':
      return 'বিনোদন';
    case 'education':
      return 'শিক্ষা';
    case 'travel':
      return 'ভ্রমণ';
    case 'rent':
      return 'ভাড়া';
    case 'other':
      return 'অন্যান্য';
    default:
      return category;
  }
}
