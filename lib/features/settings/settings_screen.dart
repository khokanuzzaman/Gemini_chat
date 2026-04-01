import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/database/expense_seed_data.dart';
import '../../core/database/models/expense_record_model.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/app_theme.dart';
import '../chat/presentation/providers/chat_provider.dart';
import '../chat/data/models/message_model.dart';
import '../expense/presentation/providers/expense_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _currencyOptions = ['৳', 'Tk', 'BDT'];
  static const _dateFormatOptions = ['d MMM yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'];
  static const _categoryOptions = [
    'Food',
    'Transport',
    'Healthcare',
    'Shopping',
    'Bill',
    'Entertainment',
    'Other',
  ];

  bool _loading = true;
  late bool _ragEnabled;
  late String _defaultCategory;
  late String _currencySymbol;
  late String _dateFormat;
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _ragEnabled = await AppPreferences.isRagEnabled();
    _defaultCategory = await AppPreferences.defaultCategory();
    _currencySymbol = await AppPreferences.currencySymbol();
    _dateFormat = await AppPreferences.dateFormat();

    if (!mounted) {
      return;
    }

    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SettingsSection(
            title: 'AI Settings',
            children: [
              SwitchListTile.adaptive(
                value: _ragEnabled,
                title: const Text('Personal data use'),
                subtitle: const Text('RAG দিয়ে আপনার খরচের data use হবে'),
                onChanged: (value) async {
                  setState(() {
                    _ragEnabled = value;
                  });
                  ref.read(ragEnabledProvider.notifier).state = value;
                  await AppPreferences.setRagEnabled(value);
                },
              ),
              _DropdownTile(
                title: 'Default category',
                value: _defaultCategory,
                items: _categoryOptions,
                onChanged: (value) async {
                  setState(() {
                    _defaultCategory = value;
                  });
                  await AppPreferences.setDefaultCategory(value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Display',
            children: [
              _DropdownTile(
                title: 'Currency symbol',
                value: _currencySymbol,
                items: _currencyOptions,
                onChanged: (value) async {
                  setState(() {
                    _currencySymbol = value;
                  });
                  await AppPreferences.setCurrencySymbol(value);
                },
              ),
              _DropdownTile(
                title: 'Date format',
                value: _dateFormat,
                items: _dateFormatOptions,
                onChanged: (value) async {
                  setState(() {
                    _dateFormat = value;
                  });
                  await AppPreferences.setDateFormat(value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Data',
            children: [
              _ActionTile(
                title: 'Export data (CSV)',
                subtitle: 'CSV file documents folder-এ save হবে',
                icon: Icons.file_download_outlined,
                onTap: _exportCsv,
              ),
              _ActionTile(
                title: 'Clear all data',
                subtitle: 'সব expense permanently remove হবে',
                icon: Icons.delete_outline_rounded,
                accentColor: AppColors.error,
                onTap: _clearAllData,
              ),
              _ActionTile(
                title: 'Seed demo data',
                subtitle: 'ডেমো expense data add করুন',
                icon: Icons.auto_awesome_outlined,
                onTap: _seedDemoData,
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('App version'),
                subtitle: Text(_version),
                contentPadding: EdgeInsets.zero,
              ),
              const ListTile(
                title: Text(AppStrings.poweredBy),
                subtitle: Text('GPT-4o mini · Whisper · ML Kit OCR'),
                contentPadding: EdgeInsets.zero,
              ),
              _ActionTile(
                title: 'GitHub link',
                subtitle: 'Copy repository link',
                icon: Icons.link_rounded,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  const link = 'https://github.com/khokanuzzaman/Gemini_chat';
                  await Clipboard.setData(const ClipboardData(text: link));
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
                    const SnackBar(content: Text(AppStrings.githubCopied)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/smartspend-export.csv');
    final expenses = await ref
        .read(expenseLocalDataSourceProvider)
        .getAllExpenses();
    final buffer = StringBuffer('date,category,description,amount\n');
    for (final expense in expenses) {
      buffer.writeln(
        '${expense.date.toIso8601String()},${expense.category},"${expense.description.replaceAll('"', '""')}",${expense.amount}',
      );
    }
    await file.writeAsString(buffer.toString());
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported: ${file.path}')));
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('সব data clear করবেন?'),
          content: const Text('Chat history আর expense data দুটোই মুছে যাবে।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(isarProvider).writeTxn(() async {
      await ref.read(isarProvider).expenseRecordModels.clear();
      await ref.read(isarProvider).messageModels.clear();
    });
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.allDataCleared)));
  }

  Future<void> _seedDemoData() async {
    await ref.read(isarProvider).writeTxn(() async {
      await ref.read(isarProvider).expenseRecordModels.clear();
    });
    await ExpenseSeedData.forceSeed(ref.read(expenseLocalDataSourceProvider));
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.demoDataSeeded)));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: title),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(growable: false),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: accentColor.withValues(alpha: 0.12),
        child: Icon(icon, color: accentColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
