part of '../../screens/expense_list_screen.dart';

class _ExpenseListScreenContent extends ConsumerStatefulWidget {
  const _ExpenseListScreenContent();

  @override
  ConsumerState<_ExpenseListScreenContent> createState() =>
      _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<_ExpenseListScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseListControllerProvider);
    final currentState = state.valueOrNull;

    return AppPageScaffold(
      title: 'খরচের তালিকা',
      showOfflineBanner: false,
      actions: [
        IconButton(
          onPressed: currentState == null
              ? null
              : () => _openFilterSheet(currentState),
          icon: const Icon(Icons.filter_alt_outlined),
          tooltip: 'ফিল্টার',
        ),
        const GlobalSettingsButton(),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openManualAdd(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: state.when(
        data: (data) => _buildDataState(context, data),
        loading: () => Padding(
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
      ),
    );
  }

  Widget _buildDataState(BuildContext context, ExpenseListState data) {
    final visibleExpenses = data.expenses
        .where((expense) {
          if (_searchQuery.isEmpty) {
            return true;
          }
          final needle = _searchQuery.toLowerCase();
          return expense.description.toLowerCase().contains(needle) ||
              expense.category.toLowerCase().contains(needle);
        })
        .toList(growable: false);
    final groupedExpenses = _groupByDate(visibleExpenses);
    final totalAmount = visibleExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Column(
      children: [
        AppFadeSlideIn(
          duration: AppMotion.fast,
          child: _ExpenseTopPanel(
            controller: _searchController,
            searchQuery: _searchQuery,
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              children: [
                AppFadeSlideIn(
                  delay: AppMotion.staggerDelay,
                  duration: AppMotion.fast,
                  child: _ExpenseSummaryStrip(
                    totalAmount: totalAmount,
                    count: visibleExpenses.length,
                    onDateTap: _pickCustomDateRange,
                    hasDateRange: data.filter.hasDateRange,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (visibleExpenses.isEmpty)
                  AppFadeSlideIn(
                    delay: AppMotion.fast,
                    child: AppEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'কোনো খরচ নেই',
                      subtitle:
                          'খরচ যোগ করতে চ্যাটে যান বা ম্যানুয়ালি যোগ করুন',
                      actionLabel: 'খরচ যোগ করুন',
                      onAction: () => _openManualAdd(context),
                    ),
                  )
                else ...[
                  for (var i = 0; i < groupedExpenses.entries.length; i++) ...[
                    AppFadeSlideIn(
                      key: ValueKey(
                        'expense-group-${groupedExpenses.entries.elementAt(i).key}',
                      ),
                      delay: Duration(
                        milliseconds: math.min(
                          AppMotion.staggerDelay.inMilliseconds * (i + 2),
                          400,
                        ),
                      ),
                      duration: AppMotion.fast,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: i == groupedExpenses.length - 1
                              ? 0
                              : AppSpacing.lg,
                        ),
                        child: _ExpenseDateSection(
                          date: groupedExpenses.entries.elementAt(i).key,
                          expenses: groupedExpenses.entries.elementAt(i).value,
                          onEdit: _openEditExpense,
                          onDelete: _confirmDeleteExpense,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<DateTime, List<ExpenseEntity>> _groupByDate(
    List<ExpenseEntity> expenses,
  ) {
    final sortedExpenses = [...expenses]
      ..sort((first, second) => second.date.compareTo(first.date));
    final grouped = <DateTime, List<ExpenseEntity>>{};

    for (final expense in sortedExpenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(expense);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((first, second) => second.date.compareTo(first.date));
    }

    return grouped;
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

  Future<void> _openManualAdd(BuildContext context) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(AppSlideUpRoute(builder: (_) => const ManualAddScreen()));

    if (saved != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('খরচ সংরক্ষণ হয়েছে'),
          backgroundColor: AppColors.success,
        ),
      );
  }

  Future<void> _openEditExpense(ExpenseEntity expense) async {
    final updated = await AppBottomSheet.show<bool>(
      context: context,
      title: 'খরচ সম্পাদনা করুন',
      maxHeightFactor: 0.92,
      child: _EditExpenseSheet(expense: expense),
    );

    if (updated != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('খরচ আপডেট হয়েছে')));
  }

  Future<void> _confirmDeleteExpense(ExpenseEntity expense) async {
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
      parts.add('ক্যাটাগরি: ${_categoryDisplayName(filter.category!)}');
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
    required this.searchQuery,
    required this.filter,
    required this.onSearchChanged,
    required this.onClearDateRange,
  });

  final TextEditingController controller;
  final String searchQuery;
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
          TextField(
            controller: controller,
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
                  label: _categoryDisplayName(category.name),
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

class _ExpenseSummaryStrip extends StatelessWidget {
  const _ExpenseSummaryStrip({
    required this.totalAmount,
    required this.count,
    required this.onDateTap,
    required this.hasDateRange,
  });

  final double totalAmount;
  final int count;
  final VoidCallback onDateTap;
  final bool hasDateRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.cardAll,
        boxShadow: context.elevationLevel(1),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${BanglaFormatters.currency(totalAmount)} মোট · ${BanglaFormatters.count(count)}টি লেনদেন',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onDateTap,
            borderRadius: AppRadius.buttonAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.mutedSurfaceColor,
                borderRadius: AppRadius.buttonAll,
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasDateRange
                        ? Icons.event_available_rounded
                        : Icons.calendar_today_rounded,
                    size: 16,
                    color: context.appColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'তারিখ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ExpenseDateSection extends StatelessWidget {
  const _ExpenseDateSection({
    required this.date,
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final List<ExpenseEntity> expenses;
  final Future<void> Function(ExpenseEntity expense) onEdit;
  final Future<void> Function(ExpenseEntity expense) onDelete;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: BanglaFormatters.relativeDay(date),
          subtitle:
              '${BanglaFormatters.fullDate(date)} · ${BanglaFormatters.currency(total)}',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < expenses.length; i++) ...[
          _ExpenseCard(
            expense: expenses[i],
            onTap: () => onEdit(expenses[i]),
            onLongPress: () => onDelete(expenses[i]),
            onDelete: () => onDelete(expenses[i]),
          ),
          if (i != expenses.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  final ExpenseEntity expense;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = resolveExpenseCategory(expense.category);
    final wallet = expense.walletId == null
        ? null
        : ref.watch(walletByIdProvider(expense.walletId!));
    final subtitleParts = <String>[
      _categoryDisplayName(expense.category),
      BanglaFormatters.fullDate(expense.date),
      if (wallet != null) '${wallet.emoji} ${wallet.name}',
    ];

    return Dismissible(
      key: ValueKey('expense-card-${expense.id}-${expense.date.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.cardAll,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      child: AppCard(
        elevation: 1,
        padding: EdgeInsets.zero,
        child: AppListTile(
          leadingEmoji: _categoryEmoji(expense.category),
          leadingColor: meta.color,
          title: expense.description,
          subtitle: subtitleParts.join(' · '),
          trailingAmount: expense.amount,
          trailingAmountIsExpense: true,
          trailingSubtitle: BanglaFormatters.time(expense.date),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  const _EditExpenseSheet({required this.expense});

  final ExpenseEntity expense;

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late String _selectedCategory;
  int? _selectedWalletId;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _amountController = TextEditingController(
      text: _formatNumber(widget.expense.amount),
    );
    _selectedCategory = widget.expense.category;
    _selectedWalletId =
        widget.expense.walletId ?? ref.read(activeWalletProvider)?.id;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final categories = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);

    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.contains('Other')
          ? 'Other'
          : categories.first;
    }

    return AppStaggeredList(
      children: [
        _EditAmountCard(controller: _amountController),
        const SizedBox(height: AppSpacing.sectionGap),
        _SheetSection(
          title: 'ক্যাটাগরি',
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                final meta = resolveExpenseCategory(category);
                return AppChip(
                  label: _categoryDisplayName(category),
                  emoji: _categoryEmoji(category),
                  color: meta.color,
                  selected: _selectedCategory == category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SheetSection(
          title: 'বিবরণ',
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.primaryTextColor,
            ),
            decoration: _sheetInputDecoration(
              context,
              hintText: 'খরচের বিবরণ লিখুন...',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SheetSection(
          title: 'তারিখ ও সময়',
          child: Column(
            children: [
              _FilterActionRow(
                icon: Icons.calendar_today_rounded,
                label: BanglaFormatters.fullDate(_selectedDate),
                actionLabel: 'তারিখ বদলান',
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilterActionRow(
                icon: Icons.access_time_rounded,
                label: BanglaFormatters.time(_selectedDate),
                actionLabel: 'সময় বদলান',
                onTap: _pickTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SheetSection(
          title: 'ওয়ালেট',
          child: WalletSelectorWidget(
            selectedWalletId: effectiveWalletId,
            onChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppActionButton(
          label: 'আপডেট করুন',
          icon: Icons.check_rounded,
          onPressed: _isSaving ? null : _save,
          isLoading: _isSaving,
          fullWidth: true,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = _parseAmount(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final selectedWalletId =
        _selectedWalletId ?? ref.read(activeWalletProvider)?.id;

    if (amount == null || amount <= 0 || description.isEmpty) {
      _showMessage('সব তথ্য ঠিকভাবে দিন');
      return;
    }

    if (selectedWalletId == null) {
      _showMessage('একটি ওয়ালেট বেছে নিন');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final error = await ref
        .read(expenseListControllerProvider.notifier)
        .updateExpense(
          widget.expense.copyWith(
            amount: amount,
            category: _selectedCategory,
            description: description,
            date: _selectedDate,
            walletId: selectedWalletId,
          ),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (error != null) {
      _showMessage(error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  double? _parseAmount(String? raw) {
    final input = (raw ?? '').trim();
    if (input.isEmpty) {
      return null;
    }

    final normalized = input
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll('٫', '.')
        .replaceAll('৳', '')
        .replaceAll(' ', '')
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9');

    final cleaned = normalized.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: context.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _EditAmountCard extends StatelessWidget {
  const _EditAmountCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '৳',
            style: AppTextStyles.heroAmount.copyWith(
              color: context.appColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.heroAmount.copyWith(
                color: context.appColors.primary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterActionRow extends StatelessWidget {
  const _FilterActionRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.appColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

InputDecoration _sheetInputDecoration(
  BuildContext context, {
  required String hintText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: context.hintTextColor),
    filled: true,
    fillColor: context.mutedSurfaceColor,
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
  );
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
