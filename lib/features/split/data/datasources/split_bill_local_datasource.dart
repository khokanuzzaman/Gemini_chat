import 'package:isar/isar.dart';

import '../../../../core/database/models/split_bill_model.dart';

class SplitBillLocalDataSource {
  const SplitBillLocalDataSource(this._isar);

  final Isar _isar;

  Future<List<SplitBillModel>> getAllSplits() async {
    final splits = await _isar.splitBillModels.where().findAll();
    splits.sort((first, second) => second.date.compareTo(first.date));
    return splits;
  }

  Future<void> saveSplit(SplitBillModel model) async {
    await _isar.writeTxn(() async {
      await _isar.splitBillModels.put(model);
    });
  }

  Future<void> updateSplit(SplitBillModel model) async {
    await _isar.writeTxn(() async {
      await _isar.splitBillModels.put(model);
    });
  }

  Future<SplitBillModel?> getSplitById(int id) {
    return _isar.splitBillModels.get(id);
  }

  Future<void> deleteSplit(int id) async {
    await _isar.writeTxn(() async {
      await _isar.splitBillModels.delete(id);
    });
  }
}
