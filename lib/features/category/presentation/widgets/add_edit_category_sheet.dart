import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/category_icon.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';

Future<void> showAddEditCategorySheet(
  BuildContext context, {
  CategoryEntity? category,
}) {
  return AppBottomSheet.show<void>(
    context: context,
    title: category == null ? 'ক্যাটাগরি যোগ করুন' : 'ক্যাটাগরি সম্পাদনা করুন',
    subtitle: category == null
        ? 'নতুন কাস্টম ক্যাটাগরি বানান'
        : 'নাম, রং ও icon পরিবর্তন করুন',
    child: _AddEditCategorySheet(category: category),
  );
}

class _AddEditCategorySheet extends ConsumerStatefulWidget {
  const _AddEditCategorySheet({this.category});

  final CategoryEntity? category;

  @override
  ConsumerState<_AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<_AddEditCategorySheet> {
  static const _presetColors = <Color>[
    Color(0xFFEA4335),
    Color(0xFFFF6D00),
    Color(0xFFF9AB00),
    Color(0xFF34A853),
    Color(0xFF1A73E8),
    Color(0xFF9334E6),
    Color(0xFFE91E63),
    Color(0xFF80868B),
    Color(0xFF8D6E63),
    Color(0xFF00897B),
    Color(0xFF3F51B5),
    Color(0xFF9CCC65),
  ];

  static const _availableIcons = <String>[
    'restaurant',
    'local_cafe',
    'fastfood',
    'directions_car',
    'directions_bus',
    'train',
    'flight',
    'local_hospital',
    'medication',
    'fitness_center',
    'shopping_bag',
    'store',
    'receipt_long',
    'home',
    'wifi',
    'phone_android',
    'school',
    'book',
    'sports_soccer',
    'movie',
    'music_note',
    'pets',
    'child_care',
    'celebration',
    'card_giftcard',
    'savings',
    'work',
    'handyman',
    'travel_explore',
    'category',
  ];

  late final TextEditingController _nameController;
  late Color _selectedColor;
  late String _selectedIcon;
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? const Color(0xFF1A73E8);
    _selectedIcon = widget.category?.icon ?? 'category';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _selectedColor.withValues(alpha: 0.15),
                child: Icon(
                  CategoryIcon.getIconData(_selectedIcon),
                  color: _selectedColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                previewName.isEmpty ? 'Preview' : previewName,
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        TextField(
          controller: _nameController,
          maxLength: 20,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Category নাম',
            hintText: 'যেমন: Education, Gym, Pet...',
          ),
        ),
        const SizedBox(height: 16),
        const Text('রং বেছে নিন', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presetColors
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: _selectedColor == color
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ]
                          : const [],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _showFullColorPicker,
          icon: const Icon(Icons.palette_outlined),
          label: const Text('আরও রং'),
        ),
        const SizedBox(height: 8),
        const Text('Icon বেছে নিন', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _availableIcons
              .map(
                (iconName) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconName;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: _selectedIcon == iconName
                          ? _selectedColor.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedIcon == iconName
                          ? Border.all(color: _selectedColor)
                          : Border.all(color: context.borderColor),
                    ),
                    child: Icon(
                      CategoryIcon.getIconData(iconName),
                      color: _selectedIcon == iconName
                          ? _selectedColor
                          : context.secondaryTextColor,
                      size: 24,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 24),
        AppActionButton(
          label: _isEditing ? 'আপডেট করুন' : 'যোগ করুন',
          fullWidth: true,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }

  Future<void> _showFullColorPicker() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var draftColor = _selectedColor;
        return AlertDialog(
          title: const Text('রং বেছে নিন'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              availableColors: _presetColors,
              onColorChanged: (color) {
                draftColor = color;
              },
            ),
          ),
          actions: [
            AppActionButton(
              label: 'বাদ দিন',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppActionButton(
              label: 'ঠিক আছে',
              onPressed: () {
                setState(() {
                  _selectedColor = draftColor;
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      _showMessage('Category নাম দিন');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(categoryProvider.notifier);
      if (_isEditing) {
        await notifier.updateCategory(
          widget.category!.copyWith(
            name: rawName,
            icon: _selectedIcon,
            colorValue: _selectedColor.toARGB32(),
          ),
        );
      } else {
        await notifier.addCategory(
          name: rawName,
          icon: _selectedIcon,
          color: _selectedColor,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on StateError catch (error) {
      if (error.message == 'budget_sync_warning') {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Category আপডেট হয়েছে, কিন্তু budget sync ব্যর্থ হয়েছে। Budget একবার যাচাই করুন।',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        Navigator.of(context).pop();
      } else {
        _showMessage(error.message.toString());
      }
    } catch (_) {
      _showMessage('Category save করা যায়নি');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
