import 'package:flutter/material.dart';

import '../../../../core/utils/category_icon.dart';
import '../../../category/domain/category_registry.dart';

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

List<String> get expenseCategories => CategoryRegistry.categoryNames;

ExpenseCategoryMeta resolveExpenseCategory(String category) {
  final resolved =
      CategoryRegistry.findByName(category) ?? CategoryRegistry.otherCategory;
  return ExpenseCategoryMeta(
    name: resolved.name,
    icon: CategoryIcon.getIconData(resolved.icon),
    color: resolved.color,
  );
}
