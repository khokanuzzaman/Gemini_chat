import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Which soft circle a hub icon sits in. Brass is only ever the SOFT background
/// with the dark glyph (never brass text/icons on a light surface) and is reserved
/// for the SMS moat and debt/EMI.
enum HubAccent { primary, brass }

/// An icon in a soft circle — the same look as Home's insight chips, a size up.
class HubIcon extends StatelessWidget {
  const HubIcon({
    super.key,
    required this.icon,
    this.accent = HubAccent.primary,
    this.size = 44,
  });

  final IconData icon;
  final HubAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, glyph) = switch (accent) {
      HubAccent.primary => (tokens.primarySoft, tokens.primary),
      HubAccent.brass => (tokens.brassSoft, context.brassGlyph),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: glyph),
    );
  }
}

/// One row of a hub: [HubIcon], a title, an optional one-line status, a chevron.
/// Used for the প্ল্যান cards (with a status) and the আরও rows (without).
class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.status,
    this.statusIsAttention = false,
    this.accent = HubAccent.primary,
    this.dense = false,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? status;

  /// Draws the status in the danger colour (over budget, overdue).
  final bool statusIsAttention;
  final HubAccent accent;
  final VoidCallback onTap;

  /// A shorter row (36dp icon) for the আরও list.
  final bool dense;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel ?? (status == null ? title : '$title, $status'),
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: dense ? 52 : 72),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: dense ? 8 : 14,
            ),
            child: Row(
              children: [
                HubIcon(icon: icon, accent: accent, size: dense ? 36 : 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: tokens.ink,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          status!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: statusIsAttention
                                ? tokens.dangerText
                                : tokens.muted,
                            fontWeight: statusIsAttention
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: tokens.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
