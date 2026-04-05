// Feature: Split
// Layer: Data

import '../../../../core/database/models/split_bill_model.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../../domain/repositories/split_bill_repository.dart';
import '../datasources/split_bill_local_datasource.dart';

class SplitBillRepositoryImpl implements SplitBillRepository {
  const SplitBillRepositoryImpl({required SplitBillLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final SplitBillLocalDataSource _localDataSource;

  @override
  Future<List<SplitBillEntity>> getAllSplits() async {
    final models = await _localDataSource.getAllSplits();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<void> saveSplit(SplitBillEntity split) {
    return _localDataSource.saveSplit(SplitBillModel.fromEntity(split));
  }

  @override
  Future<void> updateSplit(SplitBillEntity split) {
    return _localDataSource.updateSplit(SplitBillModel.fromEntity(split));
  }

  @override
  Future<void> deleteSplit(int id) {
    return _localDataSource.deleteSplit(id);
  }

  @override
  Future<void> markSettled(int id) async {
    final split = await _localDataSource.getSplitById(id);
    if (split == null) {
      return;
    }
    final updated = split.toEntity().copyWith(isSettled: true);
    await _localDataSource.updateSplit(SplitBillModel.fromEntity(updated));
  }
}
