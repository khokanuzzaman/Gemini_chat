import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../anomaly/presentation/screens/anomaly_screen.dart';
import '../../../income/domain/entities/income_entity.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../prediction/presentation/providers/prediction_provider.dart';
import '../../../prediction/presentation/widgets/prediction_card.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';

part '../widgets/analytics/analytics_screen_content.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsScreenContent();
  }
}
