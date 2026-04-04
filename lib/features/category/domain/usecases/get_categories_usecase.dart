import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<List<CategoryEntity>> call() {
    return _repository.getAllCategories();
  }
}
