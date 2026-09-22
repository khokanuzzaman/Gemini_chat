import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/export_provider.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/analytics/analytics_providers.dart';
import '../../../../core/analytics/usage_analytics.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_list_filter.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';
import 'manual_add_screen.dart';

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
