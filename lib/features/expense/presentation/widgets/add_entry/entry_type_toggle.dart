import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'entry_type.dart';

/// খরচ | আয় segmented control. The selected segment is the primary fill for খরচ and
/// the success fill for আয় (white label on both, >= 4.5:1).
class EntryTypeToggle extends StatelessWidget {
  const EntryTypeToggle({
    super.key,
    required this.type,
    required this.onChanged,
  });

  final EntryType type;
  final ValueChanged<EntryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.line),
      ),
      child: Row(
        children: [
          for (final option in EntryType.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == type,
                label: option.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == type
                          ? (option == EntryType.expense
                                ? tokens.primaryFill
                                : tokens.successFill)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      option.label,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: option == type ? tokens.onFill : tokens.muted,
                      ),
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
