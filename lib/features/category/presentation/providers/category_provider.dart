import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/models/expense_record_model.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../prediction/presentation/providers/prediction_provider.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/category_registry.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  return CategoryLocalDataSource(ref.watch(isarProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    localDataSource: ref.watch(categoryLocalDataSourceProvider),
  );
});

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});

final addCategoryUseCaseProvider = Provider<AddCategoryUseCase>((ref) {
  return AddCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final updateCategoryUseCaseProvider = Provider<UpdateCategoryUseCase>((ref) {
  return UpdateCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>((ref) {
  return DeleteCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final categoryProvider =
    NotifierProvider<CategoryNotifier, List<CategoryEntity>>(
      CategoryNotifier.new,
    );

class CategoryNotifier extends Notifier<List<CategoryEntity>> {
  @override
  List<CategoryEntity> build() {
    final initial = [...CategoryRegistry.categories];
    Future.microtask(_loadSafely);
    return initial;
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required Color color,
  }) async {
    final normalizedName = _normalizeName(name);
    _ensureUniqueName(normalizedName);

    final category = CategoryEntity(
      id: DateTime.now().microsecondsSinceEpoch,
      name: normalizedName,
      icon: icon,
      colorValue: color.toARGB32(),
      isDefault: false,
      sortOrder: state.length + 1,
      createdAt: DateTime.now(),
    );

    await ref.read(addCategoryUseCaseProvider).call(category);
    await _loadSafely();
  }

  Future<void> updateCategory(CategoryEntity category) async {
    final existing = _findById(category.id);
    if (existing == null) {
      throw StateError('Category পাওয়া যায়নি');
    }
    if (existing.isDefault) {
      throw StateError('Default category edit করা যাবে না');
    }

    final normalizedName = _normalizeName(category.name);
    _ensureUniqueName(normalizedName, excludingId: category.id);
    final updatedCategory = category.copyWith(name: normalizedName);

    if (existing.name != normalizedName) {
      await _replaceExpenseCategory(existing.name, normalizedName);
    }

    await ref.read(updateCategoryUseCaseProvider).call(updatedCategory);
    await _loadSafely();
    _notifyExpenseChanged();
  }

  Future<void> deleteCategory(int id) async {
    final category = _findById(id);
    if (category == null) {
      throw StateError('Category পাওয়া যায়নি');
    }
    if (category.isDefault) {
      throw StateError('Default category delete করা যাবে না');
    }

    await _replaceExpenseCategory(category.name, 'Other');
    await ref.read(deleteCategoryUseCaseProvider).call(id);
    await _loadSafely();
    _notifyExpenseChanged();
  }

  Future<void> reorderCustomCategories(int oldIndex, int newIndex) async {
    final customCategories = [
      for (final category in state)
        if (!category.isDefault) category,
    ];
    if (oldIndex < 0 ||
        oldIndex >= customCategories.length ||
        newIndex < 0 ||
        newIndex > customCategories.length) {
      return;
    }

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final reordered = [...customCategories];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(targetIndex, moved);

    final updated = <CategoryEntity>[
      for (final category in state)
        if (category.isDefault) category,
      for (var index = 0; index < reordered.length; index++)
        reordered[index].copyWith(
          sortOrder: defaultCategories.length + index + 1,
        ),
    ];

    final models = updated
        .map(CategoryModel.fromEntity)
        .toList(growable: false);
    await ref.read(categoryLocalDataSourceProvider).saveCategories(models);
    _applyState(updated);
  }

  Future<List<CategoryEntity>> getCategories() async {
    await _loadSafely();
    return state;
  }

  Future<void> _loadSafely() async {
    try {
      final categories = await ref.read(getCategoriesUseCaseProvider).call();
      _applyState(_withGuaranteedDefaults(categories));
    } on UnimplementedError {
      _applyState(defaultCategories);
    } catch (_) {
      _applyState(defaultCategories);
    }
  }

  void _applyState(List<CategoryEntity> categories) {
    final sorted = [...categories]
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    CategoryRegistry.setCategories(sorted);
    state = sorted;
  }

  List<CategoryEntity> _withGuaranteedDefaults(
    List<CategoryEntity> categories,
  ) {
    if (categories.isEmpty) {
      return [...defaultCategories];
    }

    final merged = [...categories];
    final names = merged.map((category) => category.name.toLowerCase()).toSet();
    for (final defaultCategory in defaultCategories) {
      if (names.contains(defaultCategory.name.toLowerCase())) {
        continue;
      }
      merged.add(defaultCategory);
    }

    merged.sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    return merged;
  }

  CategoryEntity? _findById(int id) {
    for (final category in state) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  void _ensureUniqueName(String candidate, {int? excludingId}) {
    final normalized = candidate.toLowerCase();
    final alreadyExists = state.any(
      (category) =>
          category.id != excludingId &&
          category.name.trim().toLowerCase() == normalized,
    );
    if (alreadyExists) {
      throw StateError('এই category নামটি আগে থেকেই আছে');
    }
  }

  String _normalizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('Category নাম দিন');
    }

    if (trimmed.length > 20) {
      throw StateError('Category নাম ২০ অক্ষরের মধ্যে রাখুন');
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        );
    return words.join(' ');
  }

  Future<void> _replaceExpenseCategory(String from, String to) async {
    final isar = _isarOrNull();
    if (isar == null) {
      return;
    }

    final expenses = await isar.expenseRecordModels
        .filter()
        .categoryEqualTo(from)
        .findAll();
    if (expenses.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      for (final expense in expenses) {
        expense.category = to;
      }
      await isar.expenseRecordModels.putAll(expenses);
    });
  }

  Isar? _isarOrNull() {
    try {
      return ref.read(isarProvider);
    } on UnimplementedError {
      return null;
    }
  }

  void _notifyExpenseChanged() {
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    ref.read(anomalyForceRedetectTokenProvider.notifier).state++;
    ref.read(predictionRefreshTokenProvider.notifier).state++;
  }
}
