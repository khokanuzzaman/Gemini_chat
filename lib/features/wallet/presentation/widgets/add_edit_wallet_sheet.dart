import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_provider.dart';

Future<void> showAddEditWalletSheet(
  BuildContext context, {
  WalletEntity? existingWallet,
}) {
  return AppBottomSheet.show<void>(
    context: context,
    title: existingWallet == null
        ? 'ওয়ালেট যোগ করুন'
        : 'ওয়ালেট সম্পাদনা করুন',
    subtitle: existingWallet == null
        ? 'নতুন ক্যাশ, ব্যাংক বা মোবাইল ওয়ালেট যোগ করুন'
        : 'ওয়ালেটের তথ্য আপডেট করুন',
    child: AddEditWalletSheet(existingWallet: existingWallet),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            elevation: 1,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.appColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _emojiController.text,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? (_isEditing ? 'ওয়ালেট সম্পাদনা' : 'নতুন ওয়ালেট')
                            : _nameController.text.trim(),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: context.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedType.labelBn,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
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
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.md),
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
                  trimmed.isNotEmpty && trimmed != _selectedType.defaultEmoji;
              setState(() {});
            },
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'ইমোজি দিন';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _initialBalanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
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
            const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _accountNumberController,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'একাউন্ট নম্বর (ঐচ্ছিক)',
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
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _noteController,
            maxLength: 100,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'নোট (ঐচ্ছিক)',
              hintText: 'যেমন: ব্যক্তিগত খরচ, স্যালারি একাউন্ট',
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: AppActionButton(
                  label: 'বাদ দিন',
                  variant: AppActionButtonVariant.ghost,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppActionButton(
                  label: _isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ],
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
