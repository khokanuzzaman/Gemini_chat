import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CategoryIcon {
  const CategoryIcon._();

  /// Returns the icon used for a given expense category.
  static IconData getIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Healthcare':
        return Icons.local_hospital_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bill':
        return Icons.receipt_long_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// Returns the semantic color used for a given expense category.
  static Color getColor(String category) {
    switch (category) {
      case 'Food':
        return AppColors.food;
      case 'Transport':
        return AppColors.transport;
      case 'Healthcare':
        return AppColors.healthcare;
      case 'Shopping':
        return AppColors.shopping;
      case 'Bill':
        return AppColors.bill;
      case 'Entertainment':
        return AppColors.entertainment;
      default:
        return AppColors.other;
    }
  }
}
