import '../repositories/category_repository.dart';

class DeleteCategoryUseCase {
  const DeleteCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteCategory(id);
  }
}
