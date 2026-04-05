// Feature: Split
// Layer: Domain

import '../entities/split_bill_entity.dart';
import '../repositories/split_bill_repository.dart';

class SaveSplitUseCase {
  const SaveSplitUseCase(this._repository);

  final SplitBillRepository _repository;

  Future<void> call(SplitBillEntity split) => _repository.saveSplit(split);
}
