import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_provider.dart';

Future<void> showAddEditWalletSheet(
  BuildContext context, {
  WalletEntity? existingWallet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEditWalletSheet(existingWallet: existingWallet),
  );
}

class AddEditWalletSheet extends ConsumerStatefulWidget {
  const AddEditWalletSheet({super.key, this.existingWallet});

  final WalletEntity? existingWallet;

  @override
  ConsumerState<AddEditWalletSheet> createState() => _AddEditWalletSheetState();
}

class _AddEditWalletSheetState extends ConsumerState<AddEditWalletSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  late final TextEditingController _initialBalanceController;
  late final TextEditingController _currentBalanceController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _noteController;

  late WalletType _selectedType;
  late bool _emojiCustomized;
  bool _isSaving = false;

  bool get _isEditing => widget.existingWallet != null;

  @override
  void initState() {
    super.initState();
    final wallet = widget.existingWallet;
    _selectedType = wallet?.type ?? WalletType.cash;
    _nameController = TextEditingController(text: wallet?.name ?? '');
    _emojiController = TextEditingController(
      text: wallet?.emoji ?? _selectedType.defaultEmoji,
    );
    _initialBalanceController = TextEditingController(
      text: wallet == null ? '' : _formatNumber(wallet.initialBalance),
    );
    _currentBalanceController = TextEditingController(
      text: wallet == null ? '' : _formatNumber(wallet.currentBalance),
    );
    _accountNumberController = TextEditingController(
      text: wallet?.accountNumber ?? '',
    );
    _noteController = TextEditingController(text: wallet?.note ?? '');
    _emojiCustomized =
        wallet != null && wallet.emoji.trim() != wallet.type.defaultEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _initialBalanceController.dispose();
    _currentBalanceController.dispose();
    _accountNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomInset + 16,
        ),
        child: Material(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEditing ? 'ওয়ালেট সম্পাদনা' : 'নতুন ওয়ালেট',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditing
                        ? 'নাম, ব্যালেন্স ও তথ্য আপডেট করুন'
                        : 'ক্যাশ, মোবাইল ব্যাংকিং বা ব্যাংক ওয়ালেট যোগ করুন',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'নাম',
                      hintText: 'যেমন: Cash, bKash Personal',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'ওয়ালেটের নাম দিন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WalletType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'টাইপ'),
                    items: WalletType.values
                        .map(
                          (type) => DropdownMenuItem<WalletType>(
                            value: type,
                            child: Text(type.labelBn),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _handleTypeChanged,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emojiController,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'ইমোজি',
                      hintText: 'যেমন: 💵',
                    ),
                    onChanged: (value) {
                      final trimmed = value.trim();
                      _emojiCustomized =
                          trimmed.isNotEmpty &&
                          trimmed != _selectedType.defaultEmoji;
                    },
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'ইমোজি দিন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _initialBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'প্রারম্ভিক ব্যালেন্স',
                      prefixText: '৳ ',
                    ),
                    validator: (value) {
                      final amount = _parseAmount(value);
                      if (amount == null || amount < 0) {
                        return 'সঠিক ব্যালেন্স দিন';
                      }
                      return null;
                    },
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'বর্তমান ব্যালেন্স',
                        prefixText: '৳ ',
                      ),
                      validator: (value) {
                        final amount = _parseAmount(value);
                        if (amount == null) {
                          return 'সঠিক বর্তমান ব্যালেন্স দিন';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountNumberController,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'একাউন্ট নম্বর (optional)',
                      helperText: 'শেষ ৪ ডিজিট',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isNotEmpty && trimmed.length > 4) {
                        return 'শুধু শেষ ৪ ডিজিট দিন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'নোট (optional)',
                      hintText: 'যেমন: ব্যক্তিগত খরচ, স্যালারি একাউন্ট',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('বাদ দিন'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isEditing ? 'Update করুন' : 'Save করুন'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTypeChanged(WalletType? value) {
    if (value == null) {
      return;
    }
    final previousDefault = _selectedType.defaultEmoji;
    final currentEmoji = _emojiController.text.trim();
    final shouldAutoUpdate =
        !_emojiCustomized ||
        currentEmoji.isEmpty ||
        currentEmoji == previousDefault;
    setState(() {
      _selectedType = value;
      if (shouldAutoUpdate) {
        _emojiController.text = value.defaultEmoji;
        _emojiCustomized = false;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim().isEmpty
        ? _selectedType.defaultEmoji
        : _emojiController.text.trim();
    final initialBalance = _parseAmount(_initialBalanceController.text) ?? 0;
    final existingWallet = widget.existingWallet;
    final rawCurrentBalance = _parseAmount(_currentBalanceController.text) ?? 0;
    final currentBalance = _isEditing && existingWallet != null
        ? _resolveEditedCurrentBalance(
            existingWallet,
            initialBalance,
            rawCurrentBalance,
          )
        : initialBalance;
    final accountNumber = _accountNumberController.text.trim();
    final note = _noteController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(walletProvider.notifier);
      if (_isEditing) {
        await notifier.updateWallet(
          widget.existingWallet!.copyWith(
            name: name,
            type: _selectedType,
            emoji: emoji,
            initialBalance: initialBalance,
            currentBalance: currentBalance,
            accountNumber: accountNumber.isEmpty ? null : accountNumber,
            clearAccountNumber: accountNumber.isEmpty,
            note: note.isEmpty ? null : note,
            clearNote: note.isEmpty,
            updatedAt: now,
          ),
        );
      } else {
        final wallets =
            ref.read(walletProvider).valueOrNull ?? const <WalletEntity>[];
        var maxSortOrder = 0;
        for (final wallet in wallets) {
          maxSortOrder = max(maxSortOrder, wallet.sortOrder);
        }
        await notifier.addWallet(
          WalletEntity(
            id: 0,
            name: name,
            type: _selectedType,
            emoji: emoji,
            initialBalance: initialBalance,
            currentBalance: currentBalance,
            accountNumber: accountNumber.isEmpty ? null : accountNumber,
            note: note.isEmpty ? null : note,
            sortOrder: maxSortOrder + 1,
            isArchived: false,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (!mounted) {
        return;
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'ওয়ালেট আপডেট হয়েছে' : 'ওয়ালেট যোগ করা হয়েছে',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(_messageForError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  String _messageForError(Object error) {
    if (error is Failure) {
      return error.message;
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return 'ওয়ালেট save করা যায়নি';
  }

  double _resolveEditedCurrentBalance(
    WalletEntity existing,
    double newInitial,
    double inputCurrent,
  ) {
    final originalCurrentText = _formatNumber(existing.currentBalance);
    final currentText = _currentBalanceController.text.trim();
    final currentUnchanged = currentText == originalCurrentText;

    if (currentUnchanged && newInitial != existing.initialBalance) {
      return newInitial;
    }

    return inputCurrent;
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
