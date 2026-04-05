// Feature: Split
// Layer: Domain

import '../entities/split_bill_entity.dart';

abstract class SplitBillRepository {
  Future<List<SplitBillEntity>> getAllSplits();

  Future<void> saveSplit(SplitBillEntity split);

  Future<void> updateSplit(SplitBillEntity split);

  Future<void> deleteSplit(int id);

  Future<void> markSettled(int id);
}
