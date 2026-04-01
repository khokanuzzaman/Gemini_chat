import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icon.dart';

class ExpenseCategoryMeta {
  const ExpenseCategoryMeta({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

const expenseCategories = <String>[
  'Food',
  'Transport',
  'Healthcare',
  'Shopping',
  'Bill',
  'Entertainment',
  'Other',
];

final expenseCategoryMeta = <String, ExpenseCategoryMeta>{
  'Food': ExpenseCategoryMeta(
    name: 'Food',
    icon: CategoryIcon.getIcon('Food'),
    color: AppColors.food,
  ),
  'Transport': ExpenseCategoryMeta(
    name: 'Transport',
    icon: CategoryIcon.getIcon('Transport'),
    color: AppColors.transport,
  ),
  'Healthcare': ExpenseCategoryMeta(
    name: 'Healthcare',
    icon: CategoryIcon.getIcon('Healthcare'),
    color: AppColors.healthcare,
  ),
  'Shopping': ExpenseCategoryMeta(
    name: 'Shopping',
    icon: CategoryIcon.getIcon('Shopping'),
    color: AppColors.shopping,
  ),
  'Bill': ExpenseCategoryMeta(
    name: 'Bill',
    icon: CategoryIcon.getIcon('Bill'),
    color: AppColors.bill,
  ),
  'Entertainment': ExpenseCategoryMeta(
    name: 'Entertainment',
    icon: CategoryIcon.getIcon('Entertainment'),
    color: AppColors.entertainment,
  ),
  'Other': ExpenseCategoryMeta(
    name: 'Other',
    icon: CategoryIcon.getIcon('Other'),
    color: AppColors.other,
  ),
};

ExpenseCategoryMeta resolveExpenseCategory(String category) {
  return expenseCategoryMeta[category] ?? expenseCategoryMeta['Other']!;
}
