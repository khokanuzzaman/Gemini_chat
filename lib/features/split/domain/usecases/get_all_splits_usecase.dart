// Feature: Split
// Layer: Domain

import '../entities/split_bill_entity.dart';
import '../repositories/split_bill_repository.dart';

class GetAllSplitsUseCase {
  const GetAllSplitsUseCase(this._repository);

  final SplitBillRepository _repository;

  Future<List<SplitBillEntity>> call() => _repository.getAllSplits();
}
