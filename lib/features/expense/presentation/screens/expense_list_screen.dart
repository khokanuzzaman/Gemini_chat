import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/export_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_list_filter.dart';
import '../../domain/entities/expense_source.dart';
import '../../domain/recent_activity.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';
import '../widgets/activity_list/activity_day_list.dart';
import '../widgets/add_entry/add_entry_sheet.dart';
import '../widgets/add_entry/entry_form_parts.dart' show EntryEditResult;
import '../widgets/edit/edit_expense_sheet.dart';
import '../widgets/expense_list/managed_expense_sheet.dart';

part '../widgets/expense_list/expense_list_screen_content.dart';

/// Standalone খরচ screen. Wraps [ExpenseListBody] in its own scaffold; the
/// segmented খরচ tab reuses the body directly.
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _bodyKey = GlobalKey<ExpenseListBodyState>();

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'খরচের তালিকা',
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
        const GlobalSettingsButton(),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bodyKey.currentState?.openAdd(),
        child: const Icon(Icons.add_rounded),
      ),
      body: ExpenseListBody(key: _bodyKey),
    );
  }
}
