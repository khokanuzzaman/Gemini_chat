import 'package:isar/isar.dart';

import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

class CategoryLocalDataSource {
  const CategoryLocalDataSource(this._isar);

  final Isar _isar;

  Future<List<CategoryModel>> getAllCategories() {
    return _isar.categoryModels.where().sortBySortOrder().findAll();
  }

  Future<void> saveCategory(CategoryModel model) async {
    await _isar.writeTxn(() async {
      await _isar.categoryModels.put(model);
    });
  }

  Future<void> saveCategories(List<CategoryModel> models) async {
    await _isar.writeTxn(() async {
      await _isar.categoryModels.putAll(models);
    });
  }

  Future<void> deleteCategory(int id) async {
    await _isar.writeTxn(() async {
      await _isar.categoryModels.delete(id);
    });
  }

  Future<void> seedDefaultCategories() async {
    final existing = await getAllCategories();
    final existingNames = existing
        .map((category) => category.name.trim().toLowerCase())
        .toSet();
    final missingDefaults = defaultCategories
        .where(
          (category) => !existingNames.contains(category.name.toLowerCase()),
        )
        .map(CategoryModel.fromEntity)
        .toList(growable: false);

    if (missingDefaults.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.categoryModels.putAll(missingDefaults);
    });
  }
}
