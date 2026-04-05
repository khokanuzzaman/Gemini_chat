// Feature: Split
// Layer: Domain

import '../entities/split_bill_entity.dart';
import '../repositories/split_bill_repository.dart';

class UpdateSplitUseCase {
  const UpdateSplitUseCase(this._repository);

  final SplitBillRepository _repository;

  Future<void> call(SplitBillEntity split) => _repository.updateSplit(split);
}
