import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class EntryChoice {
  const EntryChoice({
    required this.id,
    required this.label,
    this.icon,
    this.emoji,
  });

  final String id;
  final String label;
  final IconData? icon;
  final String? emoji;
}

/// Horizontal icon chips: a circle (icon or emoji) with a label under it. The
/// selected one is filled ([selectedFill] with an [onSelected] glyph); the rest are
/// a soft circle.
class EntryChoiceChips extends StatelessWidget {
  const EntryChoiceChips({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.onSelected,
    required this.selectedFill,
    required this.softFill,
    required this.softGlyph,
  });

  final List<EntryChoice> choices;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final Color selectedFill;
  final Color softFill;
  final Color softGlyph;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                button: true,
                selected: choice.id == selectedId,
                label: choice.label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelected(choice.id),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: choice.id == selectedId
                                ? selectedFill
                                : softFill,
                            shape: BoxShape.circle,
                          ),
                          child: choice.emoji != null
                              ? Text(
                                  choice.emoji!,
                                  style: const TextStyle(fontSize: 22),
                                )
                              : Icon(
                                  choice.icon,
                                  size: 22,
                                  color: choice.id == selectedId
                                      ? tokens.onFill
                                      : softGlyph,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          choice.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: choice.id == selectedId
                                ? tokens.ink
                                : tokens.muted,
                            fontWeight: choice.id == selectedId
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
