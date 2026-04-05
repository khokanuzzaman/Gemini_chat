// Feature: Split
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../providers/split_bill_provider.dart';
import '../utils/person_color.dart';
import 'add_edit_split_screen.dart';

class SplitDetailScreen extends ConsumerWidget {
  const SplitDetailScreen({super.key, required this.splitId});

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(splitBillReadyProvider);
    final splits = ref.watch(splitBillProvider);

    if (!ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    SplitBillEntity? split;
    for (final item in splits) {
      if (item.id == splitId) {
        split = item;
        break;
      }
    }

    if (split == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Split details')),
        body: const Center(child: Text('Split খুঁজে পাওয়া যায়নি')),
      );
    }

    final currentSplit = split;
    final myPerson = _resolveMyPerson(currentSplit.persons);
    final myShare = myPerson?.shareAmount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSplit.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(buildAppRoute(AddEditSplitScreen(split: currentSplit)));
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'সম্পাদনা',
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref, currentSplit),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'মুছুন',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            color: context.appColors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    BanglaFormatters.preciseCurrency(currentSplit.totalAmount),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: context.appColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('মোট খরচ', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 16,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${BanglaFormatters.count(currentSplit.persons.length)} জন',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        BanglaFormatters.fullDate(currentSplit.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ব্যক্তিভিত্তিক হিসাব',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < currentSplit.persons.length; index++) ...[
            _PersonBreakdownCard(
              person: currentSplit.persons[index],
              index: index,
            ),
            const SizedBox(height: 10),
          ],
          if (currentSplit.settlements.isNotEmpty &&
              !currentSplit.isSettled) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'পরিশোধের পরামর্শ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < currentSplit.settlements.length;
                      index++
                    )
                      Column(
                        children: [
                          _SettlementRow(
                            settlement: currentSplit.settlements[index],
                          ),
                          if (index != currentSplit.settlements.length - 1)
                            Divider(color: context.borderColor, height: 20),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (myPerson != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              color: context.appColors.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _MyShareCardContent(
                  myShare: myShare,
                  onSave: myShare > 0
                      ? () =>
                            _saveAsExpense(context, ref, currentSplit, myShare)
                      : null,
                ),
              ),
            ),
          ],
          if (!currentSplit.isSettled) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _markSettled(context, ref, currentSplit.id),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('সব পরিশোধ হয়ে গেছে'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.success,
              ),
            ),
          ],
          if (currentSplit.notes != null &&
              currentSplit.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: context.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentSplit.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  SplitPerson? _resolveMyPerson(List<SplitPerson> persons) {
    for (final person in persons) {
      if (person.name.trim() == 'আমি') {
        return person;
      }
    }
    if (persons.isEmpty) {
      return null;
    }
    return persons.first;
  }

  Future<void> _markSettled(
    BuildContext context,
    WidgetRef ref,
    int splitId,
  ) async {
    await ref.read(splitBillProvider.notifier).markSettled(splitId);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Split সম্পন্ন হয়েছে')));
  }

  Future<void> _saveAsExpense(
    BuildContext context,
    WidgetRef ref,
    SplitBillEntity split,
    double myShare,
  ) async {
    final error = await ref
        .read(splitBillProvider.notifier)
        .saveMyShareAsExpense(
          split: split,
          myShare: myShare,
          category: split.category,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'আমার অংশ expense হিসেবে save হয়েছে')),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SplitBillEntity split,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Split মুছবেন?'),
          content: Text('“${split.title}” permanently মুছে যাবে।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('মুছুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(splitBillProvider.notifier).deleteSplit(split.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Split মুছে গেছে')));
  }
}

class _MyShareCardContent extends StatelessWidget {
  const _MyShareCardContent({
    required this.myShare,
    required this.onSave,
  });

  final double myShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final amountInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('আমার অংশ', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('আমার ভাগ', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          BanglaFormatters.preciseCurrency(myShare),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
    final saveButton = ElevatedButton(
      onPressed: onSave,
      child: const Text('Expense হিসেবে save করুন'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              amountInfo,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: saveButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: amountInfo),
            const SizedBox(width: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: saveButton,
            ),
          ],
        );
      },
    );
  }
}

class _PersonBreakdownCard extends StatelessWidget {
  const _PersonBreakdownCard({required this.person, required this.index});

  final SplitPerson person;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isPositive = person.balance >= 0;
    final tint = isPositive ? AppColors.success : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: PersonColor.getColor(index),
              child: Text(
                person.name.isEmpty ? '?' : person.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ভাগ: ${BanglaFormatters.preciseCurrency(person.shareAmount)} · দিয়েছে: ${BanglaFormatters.preciseCurrency(person.amountPaid)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPositive ? 'ফেরত পাবে' : 'দিতে হবে',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  BanglaFormatters.preciseCurrency(person.balance.abs()),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: tint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.settlement});

  final SettlementSuggestion settlement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.error.withValues(alpha: 0.12),
              child: Text(
                settlement.from.isEmpty
                    ? '?'
                    : settlement.from[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                settlement.from,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: context.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                settlement.to,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              child: Text(
                settlement.to.isEmpty ? '?' : settlement.to[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          BanglaFormatters.preciseCurrency(settlement.amount),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: context.appColors.primary),
        ),
      ],
    );
  }
}
