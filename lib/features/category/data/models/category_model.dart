import 'package:isar/isar.dart';

import '../../domain/entities/category_entity.dart';

part 'category_model.g.dart';

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String name;

  late String icon;
  late int colorValue;
  late bool isDefault;
  late int sortOrder;
  late DateTime createdAt;

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      icon: icon,
      colorValue: colorValue,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  static CategoryModel fromEntity(CategoryEntity entity) {
    return CategoryModel()
      ..id = entity.id
      ..name = entity.name
      ..icon = entity.icon
      ..colorValue = entity.colorValue
      ..isDefault = entity.isDefault
      ..sortOrder = entity.sortOrder
      ..createdAt = entity.createdAt;
  }
}
