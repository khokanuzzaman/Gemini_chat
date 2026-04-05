// Feature: Split
// Layer: Domain

import '../repositories/split_bill_repository.dart';

class DeleteSplitUseCase {
  const DeleteSplitUseCase(this._repository);

  final SplitBillRepository _repository;

  Future<void> call(int id) => _repository.deleteSplit(id);
}
