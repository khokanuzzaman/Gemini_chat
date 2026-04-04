import 'package:flutter/material.dart';

final _defaultCreatedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String icon;
  final int colorValue;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  Color get color => Color(colorValue);

  bool get isDeletable => !isDefault;

  CategoryEntity copyWith({
    int? id,
    String? name,
    String? icon,
    int? colorValue,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

final defaultCategories = <CategoryEntity>[
  CategoryEntity(
    id: 1,
    name: 'Food',
    icon: 'restaurant',
    colorValue: 0xFFFF6D00,
    isDefault: true,
    sortOrder: 1,
    createdAt: _defaultCreatedAt,
  ),
  CategoryEntity(
    id: 2,
    name: 'Transport',
    icon: 'directions_car',
    colorValue: 0xFF1A73E8,
    isDefault: true,
    sortOrder: 2,
    createdAt: _defaultCreatedAt,
  ),
  CategoryEntity(
    id: 3,
    name: 'Healthcare',
    icon: 'local_hospital',
    colorValue: 0xFFEA4335,
    isDefault: true,
    sortOrder: 3,
    createdAt: _defaultCreatedAt,
  ),
  CategoryEntity(
    id: 4,
    name: 'Shopping',
    icon: 'shopping_bag',
    colorValue: 0xFF9334E6,
    isDefault: true,
    sortOrder: 4,
    createdAt: _defaultCreatedAt,
  ),
  CategoryEntity(
    id: 5,
    name: 'Bill',
    icon: 'receipt_long',
    colorValue: 0xFF00897B,
    isDefault: true,
    sortOrder: 5,
    createdAt: _defaultCreatedAt,
  ),
  CategoryEntity(
    id: 6,
    name: 'Entertainment',
    icon: 'movie',
    colorValue: 0xFFE91E63,
    isDefault: true,
    sortOrder: 6,
    createdAt: _defaultCreatedAt,
  ),
  CategoryEntity(
    id: 7,
    name: 'Other',
    icon: 'category',
    colorValue: 0xFF80868B,
    isDefault: true,
    sortOrder: 7,
    createdAt: _defaultCreatedAt,
  ),
];
