// Feature: Split
// Layer: Presentation

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../data/datasources/split_bill_local_datasource.dart';
import '../../data/repositories/split_bill_repository_impl.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../../domain/repositories/split_bill_repository.dart';
import '../../domain/usecases/delete_split_usecase.dart';
import '../../domain/usecases/get_all_splits_usecase.dart';
import '../../domain/usecases/mark_settled_usecase.dart';
import '../../domain/usecases/save_split_usecase.dart';
import '../../domain/usecases/update_split_usecase.dart';

final splitBillLocalDataSourceProvider = Provider<SplitBillLocalDataSource>((ref) {
  return SplitBillLocalDataSource(ref.watch(isarProvider));
});

final splitBillRepositoryProvider = Provider<SplitBillRepository>((ref) {
  return SplitBillRepositoryImpl(
    localDataSource: ref.watch(splitBillLocalDataSourceProvider),
  );
});

final getAllSplitsUseCaseProvider = Provider<GetAllSplitsUseCase>((ref) {
  return GetAllSplitsUseCase(ref.watch(splitBillRepositoryProvider));
});

final saveSplitUseCaseProvider = Provider<SaveSplitUseCase>((ref) {
  return SaveSplitUseCase(ref.watch(splitBillRepositoryProvider));
});

final updateSplitUseCaseProvider = Provider<UpdateSplitUseCase>((ref) {
  return UpdateSplitUseCase(ref.watch(splitBillRepositoryProvider));
});

final deleteSplitUseCaseProvider = Provider<DeleteSplitUseCase>((ref) {
  return DeleteSplitUseCase(ref.watch(splitBillRepositoryProvider));
});

final markSettledUseCaseProvider = Provider<MarkSettledUseCase>((ref) {
  return MarkSettledUseCase(ref.watch(splitBillRepositoryProvider));
});

final splitBillReadyProvider = StateProvider<bool>((ref) => false);

final splitBillProvider = NotifierProvider<SplitBillNotifier, List<SplitBillEntity>>(
  SplitBillNotifier.new,
);

class SplitBillNotifier extends Notifier<List<SplitBillEntity>> {
  bool _loadScheduled = false;

  @override
  List<SplitBillEntity> build() {
    if (!_loadScheduled) {
      _loadScheduled = true;
      Future<void>.microtask(_load);
    }
    return const [];
  }

  Future<void> _load() async {
    state = await ref.read(getAllSplitsUseCaseProvider).call();
    ref.read(splitBillReadyProvider.notifier).state = true;
  }

  Future<void> saveSplit(SplitBillEntity split) async {
    if (split.id > 0) {
      await ref.read(updateSplitUseCaseProvider).call(split);
    } else {
      await ref.read(saveSplitUseCaseProvider).call(split);
    }
    await _load();
  }

  Future<void> markSettled(int id) async {
    await ref.read(markSettledUseCaseProvider).call(id);
    await _load();
  }

  Future<void> deleteSplit(int id) async {
    await ref.read(deleteSplitUseCaseProvider).call(id);
    await _load();
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<String?> saveMyShareAsExpense({
    required SplitBillEntity split,
    required double myShare,
    required String category,
  }) {
    return ref.read(expenseMutationControllerProvider).saveManualExpense(
      ExpenseEntity(
        amount: myShare,
        category: category,
        description: split.title,
        date: split.date,
      ),
    );
  }
}
