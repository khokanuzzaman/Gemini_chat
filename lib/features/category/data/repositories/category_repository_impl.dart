import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl({
    required CategoryLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final CategoryLocalDataSource _localDataSource;

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final categories = await _localDataSource.getAllCategories();
    return categories
        .map((category) => category.toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> addCategory(CategoryEntity category) {
    return _localDataSource.saveCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) {
    return _localDataSource.saveCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> deleteCategory(int id) {
    return _localDataSource.deleteCategory(id);
  }
}
