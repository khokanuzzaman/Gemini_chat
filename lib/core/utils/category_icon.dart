import 'package:flutter/material.dart';

import '../../features/category/domain/entities/category_entity.dart';
import '../../features/category/domain/category_registry.dart';
import '../theme/app_theme.dart';

class CategoryIcon {
  const CategoryIcon._();

  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'directions_car': Icons.directions_car_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'train': Icons.train_rounded,
    'flight': Icons.flight_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'medication': Icons.medication_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'store': Icons.store_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'home': Icons.home_rounded,
    'wifi': Icons.wifi_rounded,
    'phone_android': Icons.phone_android_rounded,
    'school': Icons.school_rounded,
    'book': Icons.book_rounded,
    'sports_soccer': Icons.sports_soccer_rounded,
    'movie': Icons.movie_rounded,
    'music_note': Icons.music_note_rounded,
    'pets': Icons.pets_rounded,
    'child_care': Icons.child_care_rounded,
    'celebration': Icons.celebration_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'savings': Icons.savings_rounded,
    'work': Icons.work_rounded,
    'handyman': Icons.handyman_rounded,
    'travel_explore': Icons.travel_explore_rounded,
    'category': Icons.category_rounded,
  };

  /// Returns the icon used for a given expense category or icon name.
  static IconData getIcon(String categoryOrIcon) {
    final category = CategoryRegistry.findByName(categoryOrIcon);
    if (category != null) {
      return getIconData(category.icon);
    }
    return getIconData(categoryOrIcon);
  }

  static IconData getIconData(String iconName) {
    return _iconMap[iconName] ?? Icons.category_rounded;
  }

  static Color getColor(String category) {
    return getCategoryColor(category, CategoryRegistry.categories);
  }

  static Color getCategoryColor(
    String categoryName,
    List<CategoryEntity> categories,
  ) {
    for (final category in categories) {
      if (category.name.toLowerCase() == categoryName.trim().toLowerCase()) {
        return category.color;
      }
    }
    return AppColors.other;
  }
}
