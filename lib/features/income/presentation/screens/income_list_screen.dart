import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/income_source.dart';
import '../providers/income_providers.dart';
import '../widgets/add_edit_income_sheet.dart';
import '../../../expense/presentation/widgets/add_entry/entry_form_parts.dart'
    show EntryEditResult;
import '../../../expense/presentation/widgets/add_entry/add_entry_sheet.dart';
import '../../../expense/presentation/widgets/add_entry/entry_type.dart';
import '../../../expense/domain/recent_activity.dart';
import '../../../expense/presentation/widgets/activity_list/activity_day_list.dart';

/// Standalone আয় screen (pushed from আরও / openIncome). Wraps [IncomeListBody]
/// in its own scaffold; the segmented খরচ tab reuses the body directly.
class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final _bodyKey = GlobalKey<IncomeListBodyState>();

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'আয়ের তালিকা',
      showOfflineBanner: false,
      actions: [
        IconButton(
          onPressed: () => _bodyKey.currentState?.toggleSearch(),
          icon: const Icon(Icons.search_rounded),
          tooltip: 'খুঁজুন',
        ),
        IconButton(
          onPressed: () => _bodyKey.currentState?.openFilter(),
          icon: const Icon(Icons.filter_alt_outlined),
          tooltip: 'ফিল্টার',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.success,
        onPressed: () => _bodyKey.currentState?.openAdd(),
        child: const Icon(Icons.add_rounded),
      ),
      body: IncomeListBody(key: _bodyKey),
    );
  }
}

/// The আয় list body (no scaffold), so it can be hosted either by
/// [IncomeListScreen] or the segmented খরচ tab. [openAdd]/[openFilter] let the
/// host wire a FAB and filter action.
class IncomeListBody extends ConsumerStatefulWidget {
  const IncomeListBody({super.key});

  @override
  ConsumerState<IncomeListBody> createState() => IncomeListBodyState();
}

class IncomeListBodyState extends ConsumerState<IncomeListBody> {
  int? _selectedWalletId;
  String? _selectedSource;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _searchVisible = false;

  // Grouped rows are rebuilt only when data, wallet filter, search or wallet
  // names change — not per frame.
  List<IncomeEntity>? _memoIncome;
  int? _memoWalletId;
  String? _memoSource;
  // Default sources, plus any other source the data actually contains (imports,
  // old records) so every row stays reachable from a chip.
  List<IncomeSource> _sourceOptions = defaultIncomeSources;
  List<IncomeEntity>? _optionsFor;
  String _memoQuery = '';
  List<WalletEntity>? _memoWallets;
  List<ActivityListItem> _memoItems = const [];
  double _memoTotal = 0;
  int _memoCount = 0;

  void openAdd() => _openAddSheet();
  void openFilter() => _openFilterSheet();

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

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomeListControllerProvider);

    return state.when(
      data: (income) => _buildDataState(context, income),
      // Scrollable (but inert): the skeleton is taller than a 568dp screen.
      loading: () => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppStaggeredList(
          children: const [
            _IncomeTopPanelLoading(),
            SizedBox(height: AppSpacing.md),
            _IncomeSummaryLoading(),
            SizedBox(height: AppSpacing.md),
            AppLoadingState.list(),
          ],
        ),
      ),
      error: (error, _) => AppErrorState(
        message: error.toString(),
        onRetry: () =>
            ref.read(incomeListControllerProvider.notifier).refresh(),
      ),
    );
  }

  void _refreshMemo(List<IncomeEntity> income, List<WalletEntity> wallets) {
    if (identical(_memoIncome, income) &&
        _memoWalletId == _selectedWalletId &&
        _memoSource == _selectedSource &&
        _memoQuery == _searchQuery &&
        identical(_memoWallets, wallets)) {
      return;
    }
    final walletById = {for (final wallet in wallets) wallet.id: wallet};
    final entries = <ActivityEntry>[];
    var total = 0.0;
    for (final entry in income) {
      if (_selectedWalletId != null && entry.walletId != _selectedWalletId) {
        continue;
      }
      if (_selectedSource != null && entry.source != _selectedSource) {
        continue;
      }
      final source = findIncomeSourceByName(entry.source);
      final label = source?.banglaLabel ?? entry.source;
      if (_searchQuery.isNotEmpty &&
          !entry.description.toLowerCase().contains(_searchQuery) &&
          !label.toLowerCase().contains(_searchQuery) &&
          !entry.source.toLowerCase().contains(_searchQuery)) {
        continue;
      }
      final wallet = entry.walletId == null ? null : walletById[entry.walletId];
      final description = entry.description.trim();
      entries.add(
        ActivityEntry(
          item: RecentActivityItem(
            kind: ActivityKind.income,
            title: description.isEmpty ? label : description,
            category: entry.source,
            date: entry.date,
            amount: entry.amount,
            id: entry.id,
          ),
          subtitle: [
            label,
            if (wallet != null) '${wallet.emoji} ${wallet.name}',
          ].join(' · '),
          time: BanglaFormatters.time(entry.date),
          source: entry,
        ),
      );
      total += entry.amount;
    }
    _memoItems = buildActivityItems(entries);
    _memoTotal = total;
    _memoCount = entries.length;
    _memoIncome = income;
    _memoWalletId = _selectedWalletId;
    _memoSource = _selectedSource;
    if (!identical(_optionsFor, income)) {
      _optionsFor = income;
      final known = {for (final source in defaultIncomeSources) source.name};
      final extra = {
        for (final entry in income)
          if (!known.contains(entry.source)) entry.source,
      };
      _sourceOptions = [
        ...defaultIncomeSources,
        for (final name in extra)
          IncomeSource(
            name: name,
            banglaLabel: name,
            emoji: '💰',
            sortOrder: 1000,
          ),
      ];
    }
    _memoQuery = _searchQuery;
    _memoWallets = wallets;
  }

  Future<void> _clearAllFilters() async {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedWalletId = null;
      _selectedSource = null;
    });
  }

  Widget _buildDataState(BuildContext context, List<IncomeEntity> income) {
    final wallets =
        ref.watch(walletProvider).valueOrNull ?? const <WalletEntity>[];
    _refreshMemo(income, wallets);
    final isFiltered =
        _selectedWalletId != null ||
        _selectedSource != null ||
        _searchQuery.isNotEmpty;

    return Column(
      children: [
        AppFadeSlideIn(
          duration: AppMotion.fast,
          child: _IncomeTopPanel(
            controller: _searchController,
            showSearch: _searchVisible,
            onSearchChanged: _scheduleSearch,
            selectedWalletId: _selectedWalletId,
            onWalletChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
              });
            },
            sources: _sourceOptions,
            selectedSource: _selectedSource,
            onSourceChanged: (source) {
              setState(() {
                _selectedSource = source;
              });
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(incomeListControllerProvider.notifier).refresh(),
            color: AppColors.success,
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
                            icon: Icons.trending_up_rounded,
                            title: 'এখনো কোনো আয় নেই',
                            subtitle: 'প্রথম আয়টি যোগ করুন',
                            actionLabel: 'আয় যোগ করুন',
                            onAction: _openAddSheet,
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
                      isIncome: true,
                      onTap: (entry) =>
                          _openEditSheet(entry.source as IncomeEntity),
                      onDelete: (entry) =>
                          _confirmDeleteIncome(entry.source as IncomeEntity),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAddSheet() =>
      showAddEntrySheet(context, initialType: EntryType.income);

  Future<void> _openEditSheet(IncomeEntity entry) async {
    final result = await showEditIncomeSheet(context, entry);
    if (result == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result == EntryEditResult.deleted
                ? 'আয় মুছে ফেলা হয়েছে'
                : 'আয় আপডেট হয়েছে',
          ),
          backgroundColor: AppColors.success,
        ),
      );
  }

  Future<void> _confirmDeleteIncome(IncomeEntity entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('আয় মুছে ফেলবেন?'),
          content: Text(
            '${entry.description.trim().isEmpty ? (findIncomeSourceByName(entry.source)?.banglaLabel ?? entry.source) : entry.description}\n${BanglaFormatters.currency(entry.amount)}',
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
        .read(incomeListControllerProvider.notifier)
        .deleteIncome(entry);

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _openFilterSheet() async {
    final wallets =
        ref.read(walletProvider).valueOrNull ?? const <WalletEntity>[];

    await AppBottomSheet.show<void>(
      context: context,
      title: 'ফিল্টার',
      subtitle: 'ওয়ালেট ও উৎস অনুযায়ী আয়ের তালিকা দেখুন',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ওয়ালেট',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: 'সব ওয়ালেট',
                selected: _selectedWalletId == null,
                onTap: () {
                  setState(() {
                    _selectedWalletId = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              for (final wallet in wallets)
                AppChip(
                  label: wallet.name,
                  emoji: wallet.emoji,
                  selected: _selectedWalletId == wallet.id,
                  onTap: () {
                    setState(() {
                      _selectedWalletId = wallet.id;
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'উৎস',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: 'সব উৎস',
                selected: _selectedSource == null,
                onTap: () {
                  setState(() {
                    _selectedSource = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              for (final source in _sourceOptions)
                AppChip(
                  label: source.banglaLabel,
                  emoji: source.emoji,
                  color: AppColors.success,
                  selected: _selectedSource == source.name,
                  onTap: () {
                    setState(() {
                      _selectedSource = source.name;
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeTopPanel extends ConsumerWidget {
  const _IncomeTopPanel({
    required this.controller,
    required this.showSearch,
    required this.onSearchChanged,
    required this.selectedWalletId,
    required this.onWalletChanged,
    required this.sources,
    required this.selectedSource,
    required this.onSourceChanged,
  });

  final TextEditingController controller;
  final bool showSearch;
  final ValueChanged<String> onSearchChanged;
  final int? selectedWalletId;
  final ValueChanged<int?> onWalletChanged;
  final List<IncomeSource> sources;
  final String? selectedSource;
  final ValueChanged<String?> onSourceChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);

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
                hintText: 'আয় খুঁজুন...',
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
                      selected: selectedWalletId == null,
                      onTap: () => onWalletChanged(null),
                    );
                  }

                  final wallet = wallets[index - 1];
                  return AppChip(
                    label: wallet.name,
                    emoji: wallet.emoji,
                    selected: selectedWalletId == wallet.id,
                    onTap: () => onWalletChanged(wallet.id),
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
              itemCount: sources.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppChip(
                    label: 'সব উৎস',
                    selected: selectedSource == null,
                    onTap: () => onSourceChanged(null),
                  );
                }

                final source = sources[index - 1];
                return AppChip(
                  label: source.banglaLabel,
                  emoji: source.emoji,
                  color: AppColors.success,
                  selected: selectedSource == source.name,
                  onTap: () => onSourceChanged(source.name),
                );
              },
            ),
          ),
        ],
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

class _IncomeTopPanelLoading extends StatelessWidget {
  const _IncomeTopPanelLoading();

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
          SizedBox(height: 40, child: _InlineChipLoading()),
          SizedBox(height: AppSpacing.sm),
          SizedBox(height: 40, child: _InlineChipLoading()),
        ],
      ),
    );
  }
}

class _IncomeSummaryLoading extends StatelessWidget {
  const _IncomeSummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingState.card(height: 72);
  }
}
