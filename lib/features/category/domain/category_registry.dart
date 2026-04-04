import 'entities/category_entity.dart';

class CategoryRegistry {
  CategoryRegistry._();

  static List<CategoryEntity> _categories = List<CategoryEntity>.unmodifiable(
    defaultCategories,
  );

  static List<CategoryEntity> get categories =>
      List<CategoryEntity>.unmodifiable(_categories);

  static List<String> get categoryNames =>
      categories.map((category) => category.name).toList(growable: false);

  static void setCategories(List<CategoryEntity> categories) {
    if (categories.isEmpty) {
      _categories = List<CategoryEntity>.unmodifiable(defaultCategories);
      return;
    }

    final sorted = [...categories]
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    _categories = List<CategoryEntity>.unmodifiable(sorted);
  }

  static CategoryEntity? findById(int id) {
    for (final category in _categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  static CategoryEntity? findByName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final category in _categories) {
      if (category.name.trim().toLowerCase() == normalized) {
        return category;
      }
    }
    return null;
  }

  static CategoryEntity get otherCategory =>
      findByName('Other') ?? defaultCategories.last;
}
