part of '../../screens/expense_list_screen.dart';

class ExpenseListBody extends ConsumerStatefulWidget {
  const ExpenseListBody({super.key});

  @override
  ConsumerState<ExpenseListBody> createState() => ExpenseListBodyState();
}

class ExpenseListBodyState extends ConsumerState<ExpenseListBody> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _searchVisible = false;

  // The grouped, mapped rows are rebuilt only when the data, the search or the
  // wallet names change — never per frame — so scrolling a long list is cheap.
  List<ExpenseEntity>? _memoExpenses;
  String _memoQuery = '';
  List<WalletEntity>? _memoWallets;
  List<ActivityListItem> _memoItems = const [];
  double _memoTotal = 0;
  int _memoCount = 0;

  void openAdd() => _openManualAdd(context);

  /// App-bar search icon: shows/hides the search field (hiding clears it).
  void toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchDebounce?.cancel();
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void openFilter() {
    final currentState = ref.read(expenseListControllerProvider).valueOrNull;
    if (currentState != null) {
      _openFilterSheet(currentState);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseListControllerProvider);

    return state.when(
      data: (data) => _buildDataState(context, data),
      // Scrollable (but inert): the skeleton is taller than a 568dp screen.
      loading: () => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppStaggeredList(
          children: const [
            _TopPanelLoading(),
            SizedBox(height: AppSpacing.md),
            _SummaryLoading(),
            SizedBox(height: AppSpacing.md),
            AppLoadingState.list(),
          ],
        ),
      ),
      error: (error, _) => AppErrorState(
        message: error.toString(),
        onRetry: () =>
            ref.read(expenseListControllerProvider.notifier).refresh(),
      ),
    );
  }

  void _refreshMemo(ExpenseListState data, List<WalletEntity> wallets) {
    if (identical(_memoExpenses, data.expenses) &&
        _memoQuery == _searchQuery &&
        identical(_memoWallets, wallets)) {
      return;
    }
    final needle = _searchQuery.toLowerCase();
    final visible = needle.isEmpty
        ? data.expenses
        : data.expenses
              .where(
                (expense) =>
                    expense.description.toLowerCase().contains(needle) ||
                    expense.category.toLowerCase().contains(needle),
              )
              .toList(growable: false);
    final walletById = {for (final wallet in wallets) wallet.id: wallet};
    _memoItems = buildActivityItems([
      for (final expense in visible) _activityEntryFor(expense, walletById),
    ]);
    _memoTotal = visible.fold<double>(0, (sum, e) => sum + e.amount);
    _memoCount = visible.length;
    _memoExpenses = data.expenses;
    _memoQuery = _searchQuery;
    _memoWallets = wallets;
  }

  ActivityEntry _activityEntryFor(
    ExpenseEntity expense,
    Map<int, WalletEntity> walletById,
  ) {
    final wallet = expense.walletId == null
        ? null
        : walletById[expense.walletId];
    final categoryLabel = categoryDisplayName(expense.category);
    final description = expense.description.trim();
    return ActivityEntry(
      item: RecentActivityItem(
        kind: ActivityKind.expense,
        title: description.isEmpty ? categoryLabel : description,
        category: expense.category,
        date: expense.date,
        amount: expense.amount,
        isEmi: expense.sourceType == ExpenseSource.debtPayment,
        id: expense.id,
      ),
      subtitle: [
        categoryLabel,
        if (wallet != null) '${wallet.emoji} ${wallet.name}',
      ].join(' · '),
      time: BanglaFormatters.time(expense.date),
      source: expense,
      locked: !expense.sourceType.editableFromExpenseList,
    );
  }

  Widget _buildDataState(BuildContext context, ExpenseListState data) {
    final wallets =
        ref.watch(walletProvider).valueOrNull ?? const <WalletEntity>[];
    _refreshMemo(data, wallets);
    final isFiltered = data.filter.hasAny || _searchQuery.isNotEmpty;

    return Column(
      children: [
        AppFadeSlideIn(
          duration: AppMotion.fast,
          child: _ExpenseTopPanel(
            controller: _searchController,
            showSearch: _searchVisible,
            filter: data.filter,
            onSearchChanged: _scheduleSearch,
            onClearDateRange: () {
              ref.read(expenseListControllerProvider.notifier).clearDateRange();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(expenseListControllerProvider.notifier).refresh(),
            color: context.appColors.primary,
            backgroundColor: context.cardBackgroundColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _memoCount == 0
                        ? const SizedBox.shrink()
                        : ActivitySummaryLine(
                            total: _memoTotal,
                            count: _memoCount,
                          ),
                  ),
                ),
                if (_memoItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: isFiltered
                        ? AppEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'কিছু পাওয়া যায়নি',
                            subtitle: 'ফিল্টার বা সার্চ বদলে দেখুন',
                            actionLabel: 'ফিল্টার মুছুন',
                            onAction: _clearAllFilters,
                          )
                        : AppEmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'এখনো কোনো খরচ নেই',
                            subtitle: 'প্রথম খরচটি যোগ করুন',
                            actionLabel: 'খরচ যোগ করুন',
                            onAction: () => _openManualAdd(context),
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      // Clear the FAB so the last row is never covered.
                      96,
                    ),
                    sliver: SliverActivityList(
                      items: _memoItems,
                      isIncome: false,
                      onTap: (entry) =>
                          _openEditExpense(entry.source as ExpenseEntity),
                      onDelete: (entry) =>
                          _confirmDeleteExpense(entry.source as ExpenseEntity),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _clearAllFilters() async {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
    await ref.read(expenseListControllerProvider.notifier).clearFilters();
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchQuery = value.trim().toLowerCase();
      });
    });
  }

  Future<void> _openManualAdd(BuildContext context) =>
      showAddEntrySheet(context);

  Future<void> _openEditExpense(ExpenseEntity expense) async {
    // Debt/goal-owned rows are read-only here; see showManagedExpenseSheet.
    if (!expense.sourceType.editableFromExpenseList) {
      await showManagedExpenseSheet(context, expense);
      return;
    }
    final result = await showEditExpenseSheet(context, expense);
    if (result == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result == EntryEditResult.deleted
                ? 'খরচ মুছে ফেলা হয়েছে'
                : 'খরচ আপডেট হয়েছে',
          ),
        ),
      );
  }

  Future<void> _confirmDeleteExpense(ExpenseEntity expense) async {
    if (!expense.sourceType.editableFromExpenseList) {
      await showManagedExpenseSheet(context, expense);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('খরচ মুছে ফেলবেন?'),
          content: Text(
            '${expense.description}\n${BanglaFormatters.currency(expense.amount)}',
          ),
          actions: [
            AppActionButton(
              label: 'বাতিল',
              variant: AppActionButtonVariant.ghost,
              size: AppActionButtonSize.small,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              size: AppActionButtonSize.small,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final error = await ref
        .read(expenseListControllerProvider.notifier)
        .deleteExpense(expense);

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _openFilterSheet(ExpenseListState currentState) async {
    await AppBottomSheet.show<void>(
      context: context,
      title: 'ফিল্টার',
      subtitle: 'তারিখের রেঞ্জ ও সক্রিয় ফিল্টার দ্রুত বদলান',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'বর্তমান অবস্থা',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _currentFilterSummary(currentState.filter),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppActionButton(
            label: 'এই মাস দেখুন',
            icon: Icons.calendar_month_rounded,
            fullWidth: true,
            onPressed: () async {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, 1);
              final end = DateTime(now.year, now.month + 1, 0);
              await ref
                  .read(expenseListControllerProvider.notifier)
                  .setDateRange(start, end);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppActionButton(
            label: 'গত মাস দেখুন',
            variant: AppActionButtonVariant.secondary,
            icon: Icons.history_rounded,
            fullWidth: true,
            onPressed: () async {
              final now = DateTime.now();
              final start = now.month == 1
                  ? DateTime(now.year - 1, 12, 1)
                  : DateTime(now.year, now.month - 1, 1);
              final end = DateTime(start.year, start.month + 1, 0);
              await ref
                  .read(expenseListControllerProvider.notifier)
                  .setDateRange(start, end);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppActionButton(
            label: 'কাস্টম তারিখ বাছাই করুন',
            variant: AppActionButtonVariant.ghost,
            icon: Icons.date_range_rounded,
            fullWidth: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await _pickCustomDateRange();
            },
          ),
          if (currentState.filter.hasDateRange) ...[
            const SizedBox(height: AppSpacing.sm),
            AppActionButton(
              label: 'তারিখ ফিল্টার সরান',
              variant: AppActionButtonVariant.ghost,
              icon: Icons.close_rounded,
              fullWidth: true,
              onPressed: () async {
                await ref
                    .read(expenseListControllerProvider.notifier)
                    .clearDateRange();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppActionButton(
            label: 'সব ফিল্টার মুছুন',
            variant: AppActionButtonVariant.danger,
            icon: Icons.filter_alt_off_rounded,
            fullWidth: true,
            onPressed: () async {
              await ref
                  .read(expenseListControllerProvider.notifier)
                  .clearFilters();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppActionButton(
            label: 'এক্সপোর্ট করুন',
            variant: AppActionButtonVariant.ghost,
            icon: Icons.ios_share_rounded,
            fullWidth: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await _quickExport(context, currentState);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final currentFilter = ref
        .read(expenseListControllerProvider)
        .valueOrNull
        ?.filter;
    final initialRange = currentFilter?.hasDateRange == true
        ? DateTimeRange(
            start: currentFilter!.startDate!,
            end: currentFilter.endDate!,
          )
        : null;

    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
    );

    if (selected == null) {
      return;
    }

    await ref
        .read(expenseListControllerProvider.notifier)
        .setDateRange(selected.start, selected.end);
  }

  String _currentFilterSummary(ExpenseListFilter filter) {
    final parts = <String>[];

    if (filter.category != null) {
      parts.add('ক্যাটাগরি: ${categoryDisplayName(filter.category!)}');
    }
    if (filter.walletId != null) {
      final wallets = ref.read(walletProvider).valueOrNull;
      WalletEntity? wallet;
      if (wallets != null) {
        for (final item in wallets) {
          if (item.id == filter.walletId) {
            wallet = item;
            break;
          }
        }
      }
      if (wallet != null) {
        parts.add('ওয়ালেট: ${wallet.emoji} ${wallet.name}');
      }
    }
    if (filter.hasDateRange) {
      parts.add(
        'তারিখ: ${BanglaFormatters.dayMonth(filter.startDate!)} – ${BanglaFormatters.dayMonth(filter.endDate!)}',
      );
    }

    if (parts.isEmpty) {
      return 'এখন কোনো ফিল্টার চালু নেই';
    }

    return parts.join('\n');
  }

  Future<void> _quickExport(
    BuildContext context,
    ExpenseListState currentState,
  ) async {
    final visibleExpenses = currentState.expenses
        .where((expense) {
          if (_searchQuery.isEmpty) {
            return true;
          }
          final needle = _searchQuery.toLowerCase();
          return expense.description.toLowerCase().contains(needle) ||
              expense.category.toLowerCase().contains(needle);
        })
        .toList(growable: false);

    final filter = currentState.filter;
    final now = DateTime.now();
    final startDate = filter.startDate ?? DateTime(now.year, now.month, 1);
    final endDate = filter.endDate ?? now;

    final error = await ref
        .read(exportProvider.notifier)
        .exportExpenses(
          expenses: visibleExpenses,
          startDate: startDate,
          endDate: endDate,
          category: filter.category,
        );

    if (!context.mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}

class _ExpenseTopPanel extends ConsumerWidget {
  const _ExpenseTopPanel({
    required this.controller,
    required this.showSearch,
    required this.filter,
    required this.onSearchChanged,
    required this.onClearDateRange,
  });

  final TextEditingController controller;
  final bool showSearch;
  final ExpenseListFilter filter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearDateRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletController = ref.read(expenseListControllerProvider.notifier);
    final walletsAsync = ref.watch(walletProvider);
    final categories = ref.watch(categoryProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSearch) ...[
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: onSearchChanged,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.primaryTextColor,
              ),
              decoration: InputDecoration(
                hintText: 'খরচ খুঁজুন...',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: context.hintTextColor,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.secondaryTextColor,
                ),
                filled: true,
                fillColor: context.cardBackgroundColor,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(AppRadius.input),
                  borderSide: BorderSide(color: context.appColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            height: 40,
            child: walletsAsync.when(
              data: (wallets) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return AppChip(
                      label: 'সব ওয়ালেট',
                      selected: filter.walletId == null,
                      onTap: () => walletController.setWallet(null),
                    );
                  }

                  final wallet = wallets[index - 1];
                  return AppChip(
                    label: wallet.name,
                    emoji: wallet.emoji,
                    selected: filter.walletId == wallet.id,
                    onTap: () => walletController.setWallet(wallet.id),
                  );
                },
              ),
              loading: () => const _InlineChipLoading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppChip(
                    label: 'সব ক্যাটাগরি',
                    selected: filter.category == null,
                    onTap: () => walletController.setCategory(null),
                  );
                }

                final category = categories[index - 1];
                final meta = resolveExpenseCategory(category.name);
                return AppChip(
                  label: categoryDisplayName(category.name),
                  emoji: _categoryEmoji(category.name),
                  color: meta.color,
                  selected: filter.category == category.name,
                  onTap: () => walletController.setCategory(category.name),
                );
              },
            ),
          ),
          if (filter.hasDateRange) ...[
            const SizedBox(height: AppSpacing.sm),
            _DateRangeChip(
              label:
                  '📅 ${BanglaFormatters.dayMonth(filter.startDate!)} – ${BanglaFormatters.dayMonth(filter.endDate!)}',
              onClear: onClearDateRange,
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClear,
      borderRadius: AppRadius.buttonAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: AppRadius.buttonAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.close_rounded,
              size: 16,
              color: context.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineChipLoading extends StatelessWidget {
  const _InlineChipLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: const [
        _ChipPlaceholder(width: 110),
        SizedBox(width: AppSpacing.sm),
        _ChipPlaceholder(width: 92),
        SizedBox(width: AppSpacing.sm),
        _ChipPlaceholder(width: 104),
      ],
    );
  }
}

class _ChipPlaceholder extends StatelessWidget {
  const _ChipPlaceholder({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.buttonAll,
        border: Border.all(color: context.borderColor),
      ),
    );
  }
}

class _TopPanelLoading extends StatelessWidget {
  const _TopPanelLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLoadingState.card(height: 54),
          SizedBox(height: AppSpacing.md),
          SizedBox(height: 40, child: _InlineChipLoading()),
          SizedBox(height: AppSpacing.sm),
          SizedBox(height: 40, child: _InlineChipLoading()),
        ],
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingState.card(height: 72);
  }
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
