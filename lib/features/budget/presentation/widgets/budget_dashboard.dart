import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_display_name.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/entities/expense_source_filters.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../domain/budget_suggestions.dart';
import '../../domain/entities/budget_plan_entity.dart';
import '../providers/budget_provider.dart';

/// Space between every card on this screen (DESIGN_SPEC: 12–16).
const double _cardGap = AppSpacing.md;

class BudgetDashboard extends ConsumerWidget {
  const BudgetDashboard({
    super.key,
    required this.budget,
    required this.onRegenerate,
  });

  final BudgetPlanEntity budget;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(expenseRefreshTokenProvider);
    return FutureBuilder<List<ExpenseEntity>>(
      future: ref.read(expenseRepositoryProvider).getThisMonthExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: AppLoadingState.card(height: 220),
          );
        }

        final tokens = context.tokens;
        final expenses = (snapshot.data ?? const <ExpenseEntity>[])
            .inCategoryBudget
            .toList(growable: false);
        final totalSpent = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );
        final remaining = budget.totalBudgeted - totalSpent;
        final usage = budget.totalBudgeted <= 0
            ? 0.0
            : totalSpent / budget.totalBudgeted;
        final liveCategoryNames = ref
            .watch(categoryProvider)
            .map((category) => category.name.trim().toLowerCase())
            .toSet();

        final rows = <_CategoryUsage>[];
        var orphanedCount = 0;
        for (final entry in budget.categoryBudgets.entries) {
          if (entry.value <= 0) {
            continue;
          }
          if (!liveCategoryNames.contains(entry.key.trim().toLowerCase())) {
            orphanedCount++;
            continue;
          }
          final spent = budget.getSpentForCategory(entry.key, expenses);
          rows.add(
            _CategoryUsage(
              category: entry.key,
              limit: entry.value,
              spent: spent,
              percent: usagePercent(spent, entry.value),
            ),
          );
        }
        // Closest to (or past) the limit first — that is what needs a look.
        rows.sort((a, b) {
          final byPercent = b.percent.compareTo(a.percent);
          return byPercent != 0 ? byPercent : b.limit.compareTo(a.limit);
        });

        final sections = <Widget>[
          AppHeroCard(
            label: 'এই মাসের বাজেট',
            amount: BanglaFormatters.currency(budget.totalBudgeted),
            subtitle: remaining >= 0
                ? 'খরচ ${BanglaFormatters.currency(totalSpent)} · বাকি ${BanglaFormatters.currency(remaining)}'
                : 'খরচ ${BanglaFormatters.currency(totalSpent)} · ${BanglaFormatters.currency(-remaining)} বেশি',
            icon: Icons.account_balance_wallet_rounded,
            gradient: context.primaryGradient,
            footer: _HeroUsageBar(usage: usage),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: tokens.primary,
                    label: 'মাসিক আয়',
                    value: BanglaFormatters.currency(budget.monthlyIncome),
                    valueColor: tokens.ink,
                  ),
                ),
                const SizedBox(width: _cardGap),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.savings_outlined,
                    iconColor: tokens.successText,
                    // Income minus budget — what is left over, NOT a Goal.
                    label: 'সঞ্চয়ের জন্য থাকে',
                    value: BanglaFormatters.currency(budget.savingsAmount),
                    valueColor: tokens.successText,
                    caption: 'আয় − বাজেট',
                  ),
                ),
              ],
            ),
          ),
          _RuleNote(rule: budget.budgetRule),
          _CategoriesCard(rows: rows, orphanedCount: orphanedCount),
          const _SuggestionsCard(),
          // The old AI narration is Phase 2; with AI off nothing AI-worded shows.
          if (FeatureFlags.aiEnabled && budget.aiExplanation.trim().isNotEmpty)
            _AiNoteCard(text: budget.aiExplanation),
          AppActionButton(
            label: 'নতুন বাজেট তৈরি করুন',
            icon: Icons.refresh_rounded,
            variant: AppActionButtonVariant.secondary,
            fullWidth: true,
            onPressed: onRegenerate,
          ),
          Text(
            'তৈরি হয়েছে: ${BanglaFormatters.fullDate(budget.createdAt)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: AppStaggeredList(children: _withGaps(sections)),
        );
      },
    );
  }
}

/// AppStaggeredList adds no spacing of its own, so cards touched.
List<Widget> _withGaps(List<Widget> children) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0) const SizedBox(height: _cardGap),
    children[i],
  ],
];

class _CategoryUsage {
  const _CategoryUsage({
    required this.category,
    required this.limit,
    required this.spent,
    required this.percent,
  });

  final String category;
  final double limit;
  final double spent;
  final int percent;
}

/// Progress inside the hero: the bar and one plain sentence, no pill.
class _HeroUsageBar extends StatelessWidget {
  const _HeroUsageBar({required this.usage});

  final double usage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final percent = usage.isFinite ? (usage * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppProgressBar(
          value: usage.isFinite ? usage : 0,
          color: tokens.onHero,
          backgroundColor: tokens.onHero.withValues(alpha: 0.22),
        ),
        const SizedBox(height: 6),
        Text(
          '${BanglaFormatters.count(percent)}% ব্যবহার হয়েছে',
          style: AppTextStyles.bodySmall.copyWith(color: tokens.onHeroMuted),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppCard(
      elevation: 1,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(color: valueColor),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// "৭০/২০/১০ নিয়ম" with its one-line meaning; tap for the longer explanation.
class _RuleNote extends StatelessWidget {
  const _RuleNote({required this.rule});

  final BudgetRule rule;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppCard(
      elevation: 1,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => AppBottomSheet.show<void>(
        context: context,
        title: rule.label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rule.description,
              style: AppTextStyles.bodyLarge.copyWith(color: tokens.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'নিয়মটি শুধু আপনার আয় ভাগ করার একটা গাইড। "সঞ্চয়ের জন্য থাকে" মানে আয় থেকে বাজেট বাদ দিলে যা বাকি থাকে — এটা আলাদা কোনো লক্ষ্য নয়, কোথাও জমাও হয় না।',
              style: AppTextStyles.bodyMedium.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rule_rounded, size: 18, color: tokens.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.label,
                  style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
                ),
                Text(
                  rule.description,
                  style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.info_outline_rounded, size: 20, color: tokens.muted),
        ],
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({required this.rows, required this.orphanedCount});

  final List<_CategoryUsage> rows;
  final int orphanedCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            padding: EdgeInsets.zero,
            title: 'ক্যাটাগরি বাজেট',
            subtitle: 'খরচ বনাম বরাদ্দ — সীমার কাছাকাছি যেগুলো, আগে',
          ),
          const SizedBox(height: AppSpacing.md),
          if (orphanedCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: tokens.warningSoft,
                borderRadius: AppRadius.cardAll,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: tokens.warningText),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${BanglaFormatters.count(orphanedCount)}টি মুছে ফেলা ক্যাটাগরি লুকানো আছে।',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (rows.isEmpty)
            const AppEmptyState(
              icon: Icons.savings_outlined,
              title: 'কোনো ক্যাটাগরি বাজেট নেই',
              subtitle:
                  'নতুন বাজেট তৈরি করলে এখানে ক্যাটাগরি অনুযায়ী সীমা দেখাবে',
              compact: true,
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppSpacing.lg,
                  thickness: 1,
                  color: tokens.line,
                ),
              _CategoryRow(usage: rows[i]),
            ],
        ],
      ),
    );
  }
}

/// One flat row (no card inside the card): icon chip, name, spent / limit, a
/// status word, the bar and "N% খরচ হয়েছে".
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.usage});

  final _CategoryUsage usage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final level = limitLevel(usage.spent, usage.limit);
    final (barColor, statusColor, statusLabel) = switch (level) {
      LimitLevel.onTrack => (tokens.primary, tokens.primary, 'ঠিক আছে'),
      LimitLevel.nearLimit => (
        tokens.warning,
        tokens.warningText,
        'সীমার কাছে',
      ),
      LimitLevel.over => (tokens.danger, tokens.dangerText, 'সীমা পেরিয়েছে'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tokens.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryIcon.getIcon(usage.category),
                color: tokens.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryDisplayName(usage.category),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${BanglaFormatters.currency(usage.spent)} / ${BanglaFormatters.currency(usage.limit)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            AppChip(label: statusLabel, color: statusColor, compact: true),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(
          value: usage.limit <= 0 ? 0 : usage.spent / usage.limit,
          color: barColor,
        ),
        const SizedBox(height: 4),
        Text(
          '${BanglaFormatters.count(usage.percent)}% খরচ হয়েছে',
          style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
        ),
      ],
    );
  }
}

/// Local, rule-based limit suggestions from the user's own last-3-months
/// averages. Nothing is written until a row (or "all") is tapped.
class _SuggestionsCard extends ConsumerWidget {
  const _SuggestionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions =
        ref.watch(budgetSuggestionsProvider).valueOrNull ??
        const <CategoryLimitSuggestion>[];
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;

    Future<void> apply(List<CategoryLimitSuggestion> items) async {
      await ref.read(budgetProvider.notifier).applyLimitSuggestions(items);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সীমা বদলানো হয়েছে')));
    }

    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            padding: EdgeInsets.zero,
            title: 'সীমার পরামর্শ',
            subtitle: 'আপনার নিজের খরচের গড় থেকে — আপনি চাপ দিলে তবেই বদলাবে',
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < suggestions.length; i++) ...[
            if (i > 0)
              Divider(height: AppSpacing.lg, thickness: 1, color: tokens.line),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryDisplayName(suggestions[i].category),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestions[i].isNew
                            ? 'প্রস্তাব ${BanglaFormatters.currency(suggestions[i].suggestedLimit)}'
                            : '${BanglaFormatters.currency(suggestions[i].currentLimit)} → ${BanglaFormatters.currency(suggestions[i].suggestedLimit)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: tokens.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestions[i].reason,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppActionButton(
                  label: 'প্রয়োগ',
                  size: AppActionButtonSize.small,
                  variant: AppActionButtonVariant.secondary,
                  onPressed: () => apply([suggestions[i]]),
                ),
              ],
            ),
          ],
          if (suggestions.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            AppActionButton(
              label: 'সবগুলো প্রয়োগ করুন',
              variant: AppActionButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => apply(suggestions),
            ),
          ],
        ],
      ),
    );
  }
}

/// Phase 2 only (AI flag on): the model's narration of the plan.
class _AiNoteCard extends StatelessWidget {
  const _AiNoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppCard(
      elevation: 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: tokens.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI এর পরামর্শ',
                  style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: AppTextStyles.bodyMedium.copyWith(color: tokens.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
