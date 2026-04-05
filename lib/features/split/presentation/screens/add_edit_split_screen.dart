// Feature: Split
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../category/domain/entities/category_entity.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../providers/split_bill_provider.dart';
import '../utils/person_color.dart';

enum SplitMode { equal, custom }

class AddEditSplitScreen extends ConsumerStatefulWidget {
  const AddEditSplitScreen({
    super.key,
    this.split,
    this.initialTitle,
    this.initialTotalAmount,
    this.initialPersonCount,
    this.initialCategory,
    this.initialDate,
  });

  final SplitBillEntity? split;
  final String? initialTitle;
  final double? initialTotalAmount;
  final int? initialPersonCount;
  final String? initialCategory;
  final DateTime? initialDate;

  @override
  ConsumerState<AddEditSplitScreen> createState() => _AddEditSplitScreenState();
}

class _AddEditSplitScreenState extends ConsumerState<AddEditSplitScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _paidControllers = [];
  final List<TextEditingController> _shareControllers = [];

  late DateTime _selectedDate;
  late String _selectedCategory;
  late SplitMode _splitMode;
  bool _saving = false;

  bool get _editing => widget.split != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.split?.date ?? widget.initialDate ?? DateTime.now();
    _selectedCategory =
        widget.split?.category ?? widget.initialCategory ?? 'Food';
    _titleController.text = widget.split?.title ?? widget.initialTitle ?? '';
    _amountController.text = widget.split == null
        ? _initialAmountText(widget.initialTotalAmount)
        : _formatAmount(widget.split!.totalAmount);
    _notesController.text = widget.split?.notes ?? '';
    _splitMode = _resolveInitialMode();

    if (widget.split != null) {
      for (final person in widget.split!.persons) {
        _addPerson(
          name: person.name,
          amountPaid: person.amountPaid,
          shareAmount: person.shareAmount,
        );
      }
    } else {
      final count = (widget.initialPersonCount ?? 2).clamp(2, 8);
      _setPersonCount(count, preserveValues: false);
    }

    if (_splitMode == SplitMode.equal) {
      _applyEqualSharesToControllers();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final controller in [
      ..._nameControllers,
      ..._paidControllers,
      ..._shareControllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _availableCategories(ref.watch(categoryProvider));
    final totalAmount = _parsedAmount;
    final effectiveShares = _effectiveShareValues;
    final persons = _previewPersons;
    final perPerson = persons.isEmpty ? 0.0 : totalAmount / persons.length;
    final roundedPerPerson = _roundMoney(perPerson);
    final roundedTotal = roundedPerPerson * persons.length;
    final roundingDifference = (totalAmount - roundedTotal).abs();
    final sharesTotal = effectiveShares.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final customSharesMatch = (sharesTotal - totalAmount).abs() <= 1.0;
    final canSave = _canSave(customSharesMatch: customSharesMatch);
    final currentStep = _currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Split সম্পাদনা' : 'নতুন Bill Split'),
        actions: [
          TextButton(
            onPressed: canSave && !_saving ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(currentStep: currentStep),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill এর তথ্য',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText:
                            'কোথায়? (যেমন: Kacchi Bhai, Cox\'s Bazar trip)',
                        prefixIcon: Icon(Icons.receipt_long_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'মোট পরিমাণ',
                              prefixText: '৳ ',
                            ),
                            onChanged: (_) {
                              setState(() {
                                if (_splitMode == SplitMode.equal) {
                                  _applyEqualSharesToControllers();
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _pickDate,
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: context.mutedSurfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      BanglaFormatters.fullDate(_selectedDate),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in categories)
                          FilterChip(
                            selected: _selectedCategory == category.name,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.name == _selectedCategory
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: category.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.name),
                              ],
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category.name;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'নোট (optional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'কে কে ছিলেন?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${BanglaFormatters.count(_nameControllers.length)} জন',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.appColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'দ্রুত যোগ করুন:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var count = 2; count <= 8; count++)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _setPersonCount(count);
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                            child: Text('$count জন'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (
                      var index = 0;
                      index < _nameControllers.length;
                      index++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.borderColor),
                            color: context.mutedSurfaceColor,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: PersonColor.getColor(index),
                                child: Text(
                                  _initialForIndex(index),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _nameControllers[index],
                                  decoration: const InputDecoration(
                                    hintText: 'নাম (যেমন: রহিম)',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 96,
                                child: TextField(
                                  controller: _paidControllers[index],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '৳ দিয়েছে',
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                onPressed: _nameControllers.length > 2
                                    ? () {
                                        setState(() {
                                          _removePerson(index);
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _addPerson();
                          if (_splitMode == SplitMode.equal) {
                            _applyEqualSharesToControllers();
                          }
                        });
                      },
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 18,
                      ),
                      label: const Text('আরেকজন যোগ করুন'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ভাগ করার পদ্ধতি',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<SplitMode>(
                      segments: const [
                        ButtonSegment<SplitMode>(
                          value: SplitMode.equal,
                          icon: Icon(Icons.balance_rounded, size: 16),
                          label: Text('সমান'),
                        ),
                        ButtonSegment<SplitMode>(
                          value: SplitMode.custom,
                          icon: Icon(Icons.tune_rounded, size: 16),
                          label: Text('Custom'),
                        ),
                      ],
                      selected: {_splitMode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _splitMode = selection.first;
                          if (_splitMode == SplitMode.equal) {
                            _applyEqualSharesToControllers();
                          } else {
                            _seedCustomSharesFromEqual();
                          }
                        });
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: _splitMode == SplitMode.custom
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < _shareControllers.length;
                                    index++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _nameControllers[index].text
                                                      .trim()
                                                      .isEmpty
                                                  ? 'Person ${index + 1}'
                                                  : _nameControllers[index].text
                                                        .trim(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 96,
                                            child: TextField(
                                              controller:
                                                  _shareControllers[index],
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              textAlign: TextAlign.right,
                                              decoration: const InputDecoration(
                                                prefixText: '৳ ',
                                                isDense: true,
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      customSharesMatch
                                          ? '✓ মোট মিলছে'
                                          : 'মোট: ${BanglaFormatters.preciseCurrency(sharesTotal)} / ${BanglaFormatters.preciseCurrency(totalAmount)} — মিলছে না',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: customSharesMatch
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              color: context.appColors.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    _PreviewRow(
                      label: 'মোট:',
                      value: BanglaFormatters.preciseCurrency(totalAmount),
                    ),
                    _PreviewRow(
                      label: 'প্রতিজন:',
                      value: BanglaFormatters.preciseCurrency(perPerson),
                    ),
                    if (_splitMode == SplitMode.equal &&
                        roundingDifference >= 0.01 &&
                        _nameControllers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'প্রতিজন ${BanglaFormatters.preciseCurrency(roundedPerPerson)} (মোট ${BanglaFormatters.preciseCurrency(roundedTotal)}, পার্থক্য: ${BanglaFormatters.preciseCurrency(roundingDifference)})',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.secondaryTextColor),
                        ),
                      ),
                    if (persons.any((person) => person.amountPaid > 0)) ...[
                      const SizedBox(height: 12),
                      Divider(color: context.borderColor),
                      const SizedBox(height: 6),
                      Text(
                        'পরিশোধ:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      for (final person in persons.where(
                        (person) =>
                            person.amountPaid > 0 || person.balance != 0,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(person.name)),
                              Text(
                                person.balance >= 0
                                    ? 'ফেরত পাবে ${BanglaFormatters.preciseCurrency(person.balance.abs())}'
                                    : 'দিতে হবে ${BanglaFormatters.preciseCurrency(person.balance.abs())}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: person.balance >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSave && !_saving ? _save : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CategoryEntity> _availableCategories(List<CategoryEntity> categories) {
    final source = categories.isEmpty ? defaultCategories : categories;
    const preferred = {'Food', 'Entertainment', 'Transport', 'Other'};
    final matched = source
        .where(
          (category) =>
              preferred.contains(category.name) ||
              category.name == _selectedCategory,
        )
        .toList(growable: false);
    if (matched.isNotEmpty) {
      return matched;
    }

    return source.take(4).toList(growable: false);
  }

  SplitMode _resolveInitialMode() {
    final split = widget.split;
    if (split == null || split.persons.isEmpty) {
      return SplitMode.equal;
    }

    final distributed = _distributeEqualShares(
      split.totalAmount,
      split.persons.length,
    );
    for (var index = 0; index < split.persons.length; index++) {
      if ((split.persons[index].shareAmount - distributed[index]).abs() >
          0.01) {
        return SplitMode.custom;
      }
    }
    return SplitMode.equal;
  }

  String _initialAmountText(double? amount) {
    if (amount == null || amount <= 0) {
      return '';
    }
    return _formatAmount(amount);
  }

  String _formatAmount(double amount) {
    final rounded = _roundMoney(amount);
    if ((rounded - rounded.round()).abs() < 0.001) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(2);
  }

  String _initialForIndex(int index) {
    final name = _nameControllers[index].text.trim();
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  double get _parsedAmount => _parseMoney(_amountController.text);

  List<double> get _effectiveShareValues {
    if (_nameControllers.isEmpty) {
      return const [];
    }
    if (_splitMode == SplitMode.equal) {
      return _distributeEqualShares(_parsedAmount, _nameControllers.length);
    }
    return _normalizedCustomShares();
  }

  List<SplitPerson> get _previewPersons {
    final shares = _effectiveShareValues;
    return List.generate(_nameControllers.length, (index) {
      final name = _nameControllers[index].text.trim();
      return SplitPerson(
        name: name.isEmpty ? 'Person ${index + 1}' : name,
        amountPaid: _parseMoney(_paidControllers[index].text),
        shareAmount: shares[index],
      );
    });
  }

  int get _currentStep {
    if (_titleController.text.trim().isEmpty || _parsedAmount <= 0) {
      return 1;
    }
    final namesFilled =
        _nameControllers.length >= 2 &&
        _nameControllers.every(
          (controller) => controller.text.trim().isNotEmpty,
        );
    return namesFilled ? 3 : 2;
  }

  bool _canSave({required bool customSharesMatch}) {
    final namesFilled =
        _nameControllers.length >= 2 &&
        _nameControllers.every(
          (controller) => controller.text.trim().isNotEmpty,
        );
    if (_saving ||
        _titleController.text.trim().isEmpty ||
        _parsedAmount <= 0 ||
        !namesFilled) {
      return false;
    }
    if (_splitMode == SplitMode.custom && !customSharesMatch) {
      return false;
    }
    return true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked;
    });
  }

  void _setPersonCount(int count, {bool preserveValues = true}) {
    while (_nameControllers.length < count) {
      _addPerson();
    }
    while (_nameControllers.length > count) {
      _removePerson(_nameControllers.length - 1);
    }
    if (!preserveValues) {
      for (var index = 0; index < _nameControllers.length; index++) {
        _nameControllers[index].text = index == 0
            ? 'আমি'
            : 'Person ${index + 1}';
        _paidControllers[index].clear();
      }
    }
    if (_splitMode == SplitMode.equal) {
      _applyEqualSharesToControllers();
    }
  }

  void _addPerson({
    String? name,
    double amountPaid = 0,
    double shareAmount = 0,
  }) {
    final nextIndex = _nameControllers.length + 1;
    _nameControllers.add(
      TextEditingController(
        text: name ?? (nextIndex == 1 ? 'আমি' : 'Person $nextIndex'),
      ),
    );
    _paidControllers.add(
      TextEditingController(
        text: amountPaid > 0 ? _formatAmount(amountPaid) : '',
      ),
    );
    _shareControllers.add(
      TextEditingController(
        text: shareAmount > 0 ? _formatAmount(shareAmount) : '',
      ),
    );
  }

  void _removePerson(int index) {
    _nameControllers.removeAt(index).dispose();
    _paidControllers.removeAt(index).dispose();
    _shareControllers.removeAt(index).dispose();
  }

  void _applyEqualSharesToControllers() {
    final shares = _distributeEqualShares(
      _parsedAmount,
      _shareControllers.length,
    );
    for (var index = 0; index < _shareControllers.length; index++) {
      _shareControllers[index].text = shares[index] > 0
          ? _formatAmount(shares[index])
          : '';
    }
  }

  void _seedCustomSharesFromEqual() {
    final shares = _distributeEqualShares(
      _parsedAmount,
      _shareControllers.length,
    );
    for (var index = 0; index < _shareControllers.length; index++) {
      if (_parseMoney(_shareControllers[index].text) <= 0) {
        _shareControllers[index].text = shares[index] > 0
            ? _formatAmount(shares[index])
            : '';
      }
    }
  }

  List<double> _normalizedCustomShares() {
    final shares = _shareControllers
        .map((controller) => _roundMoney(_parseMoney(controller.text)))
        .toList(growable: false);
    final total = shares.fold<double>(0, (sum, value) => sum + value);
    final difference = _roundMoney(_parsedAmount - total);
    if (shares.isNotEmpty &&
        difference.abs() <= 1 &&
        difference.abs() >= 0.01) {
      final adjusted = [...shares];
      adjusted[adjusted.length - 1] = _roundMoney(adjusted.last + difference);
      return adjusted;
    }
    return shares;
  }

  List<double> _distributeEqualShares(double total, int count) {
    if (count <= 0 || total <= 0) {
      return List<double>.filled(count, 0, growable: false);
    }

    final totalPaisa = (total * 100).round();
    final base = totalPaisa ~/ count;
    final remainder = totalPaisa % count;
    return List<double>.generate(count, (index) {
      final paisa = base + (index < remainder ? 1 : 0);
      return paisa / 100;
    }, growable: false);
  }

  double _parseMoney(String input) {
    const banglaDigits = {
      '০': '0',
      '১': '1',
      '২': '2',
      '৩': '3',
      '৪': '4',
      '৫': '5',
      '৬': '6',
      '৭': '7',
      '৮': '8',
      '৯': '9',
    };
    final normalized = input
        .split('')
        .map((char) => banglaDigits[char] ?? char)
        .join()
        .replaceAll(',', '')
        .replaceAll('৳', '')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }

  double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  Future<void> _save() async {
    final totalAmount = _parsedAmount;
    final shares = _effectiveShareValues;
    final persons = List.generate(_nameControllers.length, (index) {
      return SplitPerson(
        name: _nameControllers[index].text.trim(),
        amountPaid: _parseMoney(_paidControllers[index].text),
        shareAmount: shares[index],
      );
    }, growable: false);

    setState(() {
      _saving = true;
    });

    try {
      final entity = SplitBillEntity(
        id: widget.split?.id ?? 0,
        title: _titleController.text.trim(),
        totalAmount: totalAmount,
        persons: persons,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isSettled: widget.split?.isSettled ?? false,
        category: _selectedCategory,
      );
      await ref.read(splitBillProvider.notifier).saveSplit(entity);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Split save হয়েছে')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
          width: active ? 18 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? context.appColors.primary : context.borderColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
