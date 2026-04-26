import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/mutation_result.dart';
import '../../domain/entities/debt_entity.dart';

extension DebtTypePresentation on DebtType {
  String get labelBn => switch (this) {
    DebtType.iOwe => 'দেনা',
    DebtType.theyOwe => 'পাওনা',
  };

  String get selectorTitleBn => switch (this) {
    DebtType.theyOwe => 'আমাকে দিবে',
    DebtType.iOwe => 'আমি দিব',
  };

  String get selectorSubtitleBn => switch (this) {
    DebtType.theyOwe => '(পাওনা)',
    DebtType.iOwe => '(দেনা)',
  };

  IconData get directionIcon => switch (this) {
    DebtType.theyOwe => Icons.arrow_downward_rounded,
    DebtType.iOwe => Icons.arrow_upward_rounded,
  };

  Color get accentColor => switch (this) {
    DebtType.theyOwe => AppColors.success,
    DebtType.iOwe => AppColors.error,
  };

  Gradient get gradient => switch (this) {
    DebtType.theyOwe => AppGradients.success,
    DebtType.iOwe => AppGradients.danger,
  };
}

extension DebtStatusPresentation on DebtStatus {
  String get labelBn => switch (this) {
    DebtStatus.active => 'সক্রিয়',
    DebtStatus.settled => 'পরিশোধিত',
    DebtStatus.overdue => 'মেয়াদোত্তীর্ণ',
    DebtStatus.cancelled => 'বাতিল',
  };

  Color get accentColor => switch (this) {
    DebtStatus.active => AppColors.primary,
    DebtStatus.settled => AppColors.success,
    DebtStatus.overdue => AppColors.error,
    DebtStatus.cancelled => AppColors.grey600,
  };
}

extension DebtEntityPresentation on DebtEntity {
  String get detailLabelBn => isEMI ? '$displayType · কিস্তি' : displayType;

  String get modeBadgeLabelBn => isEMI ? 'কিস্তি' : 'সাধারণ';
}

void showDebtMutationResultSnackBar(
  BuildContext context,
  MutationResult result,
) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final backgroundColor = !result.isSuccess
      ? AppColors.error
      : result.hasWarnings
      ? AppColors.warning
      : AppColors.success;
  final text = result.hasWarnings
      ? '${result.message} · ${result.warnings.join(' · ')}'
      : result.message;

  messenger.showSnackBar(
    SnackBar(content: Text(text), backgroundColor: backgroundColor),
  );
}
