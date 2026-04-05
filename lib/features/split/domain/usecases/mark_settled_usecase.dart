// Feature: Split
// Layer: Domain

import '../repositories/split_bill_repository.dart';

class MarkSettledUseCase {
  const MarkSettledUseCase(this._repository);

  final SplitBillRepository _repository;

  Future<void> call(int id) => _repository.markSettled(id);
}
