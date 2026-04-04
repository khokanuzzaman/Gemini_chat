import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class AddCategoryUseCase {
  const AddCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<void> call(CategoryEntity category) {
    return _repository.addCategory(category);
  }
}
