import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_provider.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.onManualAdd});

  final VoidCallback onManualAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);
    final tokens = context.tokens;
    // Light: white label on the deep warning fill (5.46:1). Dark: the warning
    // tone is light, so the label flips to the canvas ink (8.9:1).
    final isDark = context.isDarkMode;
    final background = isDark ? tokens.warning : tokens.warningText;
    final foreground = isDark ? tokens.canvas : tokens.onFill;

    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: isOnline ? 0 : 40,
        color: background,
        child: isOnline
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: foreground, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Offline mode',
                      style: TextStyle(color: foreground, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onManualAdd,
                      style: TextButton.styleFrom(
                        foregroundColor: foreground,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Manual add',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
