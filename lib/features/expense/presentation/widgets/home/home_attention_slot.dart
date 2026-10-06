import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/backup/backup_providers.dart';
import '../../../../../core/navigation/app_page_route.dart';
import '../../../../settings/backup_screen.dart';
import '../dashboard/backup_reminder_card.dart';
import '../dashboard/restore_backup_banner.dart';

/// The ONE place Home asks for the user's attention about their data, below the
/// monthly-spend card. Only one thing shows at a time, in priority order:
/// **restore a found backup > "no recent backup" reminder**. (The SMS card is
/// separate — it is a feature, not a warning.)
class HomeAttentionSlot extends ConsumerWidget {
  const HomeAttentionSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restorePrompt = ref.watch(restorePromptProvider);
    if (restorePrompt != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: RestoreBackupBanner(
          info: restorePrompt,
          onRestore: () =>
              Navigator.of(context).push(buildAppRoute(const BackupScreen())),
          onSkip: () => ref.read(restorePromptProvider.notifier).state = null,
        ),
      );
    }
    // Renders nothing (and no spacing) when there is no reminder to show.
    return const BackupReminderCard();
  }
}
