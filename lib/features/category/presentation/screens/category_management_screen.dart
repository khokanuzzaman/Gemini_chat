import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icon.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';
import '../widgets/add_edit_category_sheet.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final defaultItems = [
      for (final category in categories)
        if (category.isDefault) category,
    ];
    final customItems = [
      for (final category in categories)
        if (!category.isDefault) category,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () => showAddEditCategorySheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Default categories',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var index = 0; index < defaultItems.length; index++) ...[
                  _CategoryTile(
                    category: defaultItems[index],
                    trailing: Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: context.secondaryTextColor,
                    ),
                  ),
                  if (index != defaultItems.length - 1)
                    Divider(height: 1, color: context.borderColor),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'আপনার categories',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          if (customItems.isEmpty)
            const _EmptyCustomCategories()
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(categoryProvider.notifier)
                    .reorderCustomCategories(oldIndex, newIndex);
              },
              itemCount: customItems.length,
              itemBuilder: (context, index) {
                final category = customItems[index];
                return Container(
                  key: ValueKey('custom-category-${category.id}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey('dismiss-category-${category.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) =>
                        _confirmDelete(context, ref, category),
                    child: Card(
                      child: _CategoryTile(
                        category: category,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => showAddEditCategorySheet(
                                context,
                                category: category,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Category মুছবেন?'),
          content: Text(
            '"${category.name}" মুছে গেলে এই category র সব expense "Other" এ চলে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('বাদ দিন'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('মুছুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    try {
      await ref.read(categoryProvider.notifier).deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category মুছে ফেলা হয়েছে')),
        );
      }
      return true;
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
      return false;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category delete করা যায়নি')),
        );
      }
      return false;
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.trailing});

  final CategoryEntity category;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.color.withValues(alpha: 0.15),
        child: Icon(
          CategoryIcon.getIconData(category.icon),
          color: category.color,
          size: 20,
        ),
      ),
      title: Text(category.name),
      trailing: trailing,
    );
  }
}

class _EmptyCustomCategories extends StatelessWidget {
  const _EmptyCustomCategories();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 10),
            const Text('কোনো custom category নেই'),
            const SizedBox(height: 4),
            Text(
              '+ বাটন দিয়ে নতুন বানান',
              style: AppTextStyles.caption.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
