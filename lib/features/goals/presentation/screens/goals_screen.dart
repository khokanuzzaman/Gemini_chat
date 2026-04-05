import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('আমার লক্ষ্য')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: goals.when(
        data: (items) {
          final activeGoals = items
              .where((goal) => goal.status == GoalStatus.active)
              .toList(growable: false);

          if (activeGoals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 12),
                    const Text(
                      'কোনো লক্ষ্য নেই',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'নতুন saving goal set করুন',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showGoalSheet(context, ref),
                      child: const Text('লক্ষ্য যোগ করুন'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: activeGoals.length,
            itemBuilder: (context, index) {
              final goal = activeGoals[index];
              final progressColor = goal.progressPercentage >= 70
                  ? AppColors.success
                  : goal.progressPercentage >= 40
                  ? AppColors.warning
                  : Theme.of(context).colorScheme.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              goal.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: AppTextStyles.titleLarge,
                                  ),
                                  Text(
                                    '${BanglaFormatters.currency(goal.savedAmount)} / ${BanglaFormatters.currency(goal.targetAmount)}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: goal.progressPercentage / 100,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          color: progressColor,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${goal.progressPercentage.toStringAsFixed(0)}%',
                            ),
                            const Spacer(),
                            Text(
                              '${goal.daysRemaining} দিন বাকি',
                              style: TextStyle(
                                color: goal.daysRemaining < 30
                                    ? AppColors.warning
                                    : context.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'মাসে ${BanglaFormatters.currency(goal.requiredMonthlySaving)} save করতে হবে',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _showAddSavingDialog(context, ref, goal),
                              child: const Text('৳ যোগ করুন'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showGoalSheet(
                                context,
                                ref,
                                existingGoal: goal,
                              ),
                              child: const Text('সম্পাদনা'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

Future<void> _showAddSavingDialog(
  BuildContext context,
  WidgetRef ref,
  GoalEntity goal,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _AddSavingDialog(goal: goal),
  );
}

Future<void> _showGoalSheet(
  BuildContext context,
  WidgetRef ref, {
  GoalEntity? existingGoal,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GoalEditorSheet(existingGoal: existingGoal),
  );
}

class _AddSavingDialog extends ConsumerStatefulWidget {
  const _AddSavingDialog({required this.goal});

  final GoalEntity goal;

  @override
  ConsumerState<_AddSavingDialog> createState() => _AddSavingDialogState();
}

class _AddSavingDialogState extends ConsumerState<_AddSavingDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.goal.title} এ সেভিং যোগ করুন'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(prefixText: '৳ ', hintText: '1000'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বাদ দিন'),
        ),
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final amount = double.tryParse(_controller.text.trim());
            if (amount == null || amount <= 0) {
              return;
            }
            await ref
                .read(goalsProvider.notifier)
                .addSaving(widget.goal.id, amount);
            if (!mounted) {
              return;
            }
            navigator.pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _GoalEditorSheet extends ConsumerStatefulWidget {
  const _GoalEditorSheet({this.existingGoal});

  final GoalEntity? existingGoal;

  @override
  ConsumerState<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<_GoalEditorSheet> {
  static const _emojis = [
    '🏠',
    '🚗',
    '✈️',
    '📱',
    '💍',
    '🎓',
    '🏥',
    '💰',
    '🛒',
    '🎮',
    '📚',
    '🏋',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late String _selectedEmoji;
  late DateTime _selectedDate;
  String _aiMonthlySuggestion = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingGoal?.title ?? '',
    );
    _targetController = TextEditingController(
      text: widget.existingGoal == null
          ? ''
          : widget.existingGoal!.targetAmount.toStringAsFixed(0),
    );
    _savedController = TextEditingController(
      text: widget.existingGoal == null
          ? '0'
          : widget.existingGoal!.savedAmount.toStringAsFixed(0),
    );
    _selectedEmoji = widget.existingGoal?.emoji ?? _emojis.first;
    _selectedDate =
        widget.existingGoal?.targetDate ??
        DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = double.tryParse(_targetController.text.trim()) ?? 0;
    final saved = double.tryParse(_savedController.text.trim()) ?? 0;
    final remaining = (target - saved).clamp(0.0, double.infinity).toDouble();
    final months = _selectedDate.difference(DateTime.now()).inDays / 30;
    final monthly = months <= 0 ? remaining : remaining / months;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existingGoal == null ? 'নতুন লক্ষ্য' : 'লক্ষ্য সম্পাদনা',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis
                  .map((emoji) {
                    final selected = _selectedEmoji == emoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12)
                              : context.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : context.borderColor,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '৳ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _savedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Already saved',
                prefixText: '৳ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Target date'),
              subtitle: Text(BanglaFormatters.fullDate(_selectedDate)),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 10),
                );
                if (picked != null && mounted) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _aiMonthlySuggestion =
                      'মাসে ${BanglaFormatters.currency(monthly)} save করতে হবে';
                });
              },
              child: const Text('AI দিয়ে monthly saving calculate করুন'),
            ),
            if (_aiMonthlySuggestion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_aiMonthlySuggestion, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final targetAmount = double.tryParse(
                    _targetController.text.trim(),
                  );
                  final savedAmount =
                      double.tryParse(_savedController.text.trim()) ?? 0;
                  final title = _titleController.text.trim();
                  if (title.isEmpty ||
                      targetAmount == null ||
                      targetAmount <= 0) {
                    return;
                  }

                  final goal = GoalEntity(
                    id: widget.existingGoal?.id ?? 0,
                    title: title,
                    emoji: _selectedEmoji,
                    targetAmount: targetAmount,
                    savedAmount: savedAmount,
                    targetDate: _selectedDate,
                    createdAt: widget.existingGoal?.createdAt ?? DateTime.now(),
                    status: savedAmount >= targetAmount
                        ? GoalStatus.achieved
                        : GoalStatus.active,
                  );
                  if (widget.existingGoal == null) {
                    await ref.read(goalsProvider.notifier).addGoal(goal);
                  } else {
                    await ref.read(goalsProvider.notifier).updateGoal(goal);
                  }
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
