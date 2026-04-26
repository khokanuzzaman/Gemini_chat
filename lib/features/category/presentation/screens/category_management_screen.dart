import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/widgets/widgets.dart';
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

    return AppPageScaffold(
      title: 'ক্যাটাগরি',
      actions: [
        IconButton(
          onPressed: () => showAddEditCategorySheet(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const AppSectionHeader(title: 'ডিফল্ট ক্যাটাগরি'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            elevation: 1,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < defaultItems.length; index++) ...[
                  _CategoryTile(
                    category: defaultItems[index],
                    trailing: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: context.secondaryTextColor,
                    ),
                  ),
                  if (index != defaultItems.length - 1)
                    Divider(height: 1, color: context.borderColor),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const AppSectionHeader(title: 'আপনার ক্যাটাগরি'),
          const SizedBox(height: AppSpacing.sm),
          if (customItems.isEmpty)
            const AppEmptyState(
              icon: Icons.category_outlined,
              title: 'কোনো কাস্টম ক্যাটাগরি নেই',
              subtitle: 'নতুন ক্যাটাগরি যোগ করতে উপরের + বাটন ব্যবহার করুন',
              compact: true,
            )
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
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Dismissible(
                    key: ValueKey('dismiss-category-${category.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: AppRadius.cardAll,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) =>
                        _confirmDelete(context, ref, category),
                    child: AppCard(
                      elevation: 1,
                      padding: EdgeInsets.zero,
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
          title: const Text('ক্যাটাগরি মুছবেন?'),
          content: Text(
            '"${category.name}" মুছে গেলে এই ক্যাটাগরির সব expense "Other" এ চলে যাবে।',
          ),
          actions: [
            AppActionButton(
              label: 'বাদ দিন',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
          const SnackBar(content: Text('ক্যাটাগরি মুছে ফেলা হয়েছে')),
        );
      }
      return true;
    } on StateError catch (error) {
      if (error.message == 'budget_sync_warning') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ক্যাটাগরি মুছে গেছে, কিন্তু budget sync ব্যর্থ হয়েছে। Budget একবার যাচাই করুন।',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return true;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
      return false;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ক্যাটাগরি delete করা যায়নি')),
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
    return AppListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          CategoryIcon.getIconData(category.icon),
          color: category.color,
          size: 20,
        ),
      ),
      title: category.name,
      subtitle: category.isDefault ? 'ডিফল্ট ক্যাটাগরি' : 'কাস্টম ক্যাটাগরি',
      trailing: trailing,
    );
  }
}
