import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/utils/category_icon.dart';

void main() {
  test('all supported categories return configured icons and colors', () {
    expect(CategoryIcon.getIcon('Food'), Icons.restaurant_rounded);
    expect(CategoryIcon.getColor('Food'), AppColors.food);

    expect(CategoryIcon.getIcon('Transport'), Icons.directions_car_rounded);
    expect(CategoryIcon.getColor('Transport'), AppColors.transport);

    expect(CategoryIcon.getIcon('Healthcare'), Icons.local_hospital_rounded);
    expect(CategoryIcon.getColor('Healthcare'), AppColors.healthcare);

    expect(CategoryIcon.getIcon('Shopping'), Icons.shopping_bag_rounded);
    expect(CategoryIcon.getColor('Shopping'), AppColors.shopping);

    expect(CategoryIcon.getIcon('Bill'), Icons.receipt_long_rounded);
    expect(CategoryIcon.getColor('Bill'), AppColors.bill);

    expect(CategoryIcon.getIcon('Entertainment'), Icons.movie_rounded);
    expect(CategoryIcon.getColor('Entertainment'), AppColors.entertainment);
  });

  test('unknown category falls back to Other visuals', () {
    expect(CategoryIcon.getIcon('Unknown'), Icons.category_rounded);
    expect(CategoryIcon.getColor('Unknown'), AppColors.other);
  });
}
