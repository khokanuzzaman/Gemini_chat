import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/backup/backup_encryption_service.dart';
import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_orchestrator.dart';
import 'package:gemini_chat/core/backup/backup_progress.dart';
import 'package:gemini_chat/core/backup/backup_providers.dart';
import 'package:gemini_chat/core/backup/drive_backup_service.dart';
import 'package:gemini_chat/core/backup/google_auth_service.dart';
import 'package:gemini_chat/core/backup/isar_export_service.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/widgets/app_hero_card.dart';
import 'package:gemini_chat/features/settings/backup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  Future<void> pumpSignedOut(WidgetTester tester, {double scale = 1.0}) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        googleAuthServiceProvider.overrideWithValue(_SignedOutAuth()),
        backupOrchestratorProvider.overrideWithValue(_NoCloudOrchestrator()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const BackupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out: one sign-in action, no pill in the hero', (
    tester,
  ) async {
    await pumpSignedOut(tester);
    expect(find.text('Google দিয়ে সাইন ইন'), findsOneWidget);
    expect(find.text('সাইন ইন'), findsNothing);
  });

  testWidgets('signed out: backup, auto-backup and delete are disabled', (
    tester,
  ) async {
    await pumpSignedOut(tester);
    await tester.scrollUntilVisible(
      find.text('সব ব্যাকআপ মুছুন'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNull);
    expect(sw.value, isFalse);
    expect(find.text('আগে Google দিয়ে সাইন ইন করুন'), findsNWidgets(2));
  });

  testWidgets('signed out: "এখনই ব্যাকআপ করুন" has no action and looks inert', (
    tester,
  ) async {
    await pumpSignedOut(tester);
    final inkWell = find.ancestor(
      of: find.text('এখনই ব্যাকআপ করুন'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(inkWell.first).onTap, isNull);
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('এখনই ব্যাকআপ করুন'),
            matching: find.byType(Material),
          )
          .first,
    );
    final tokens = AppTokens.light;
    expect(material.color, tokens.surface2);
  });

  testWidgets('hero text never overlaps and stays inside the card at ×1.3', (
    tester,
  ) async {
    await pumpSignedOut(tester, scale: 1.3);
    final hero = tester.getRect(find.byType(AppHeroCard));
    final texts = find.descendant(
      of: find.byType(AppHeroCard),
      matching: find.byType(Text),
    );
    for (final e in texts.evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(hero.contains(r.topLeft), isTrue);
      expect(r.right <= hero.right + 0.5, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero text on the gradient meets WCAG AA', (tester) async {
    for (final t in [AppTokens.light, AppTokens.dark]) {
      for (final fg in [t.onHero, t.onHeroMuted]) {
        for (final bg in [t.heroStart, t.heroEnd]) {
          final l1 = fg.computeLuminance();
          final l2 = bg.computeLuminance();
          final hi = l1 > l2 ? l1 : l2;
          final lo = l1 > l2 ? l2 : l1;
          expect((hi + 0.05) / (lo + 0.05), greaterThanOrEqualTo(4.5));
        }
      }
    }
  });
}

class _SignedOutAuth implements GoogleAuthService {
  @override
  Future<void> deleteCurrentUser() async {}
  @override
  Future<void> reauthenticate() async {}
  @override
  String? get displayName => null;
  @override
  Future<http.Client?> getDriveHttpClient() async => null;
  @override
  Future<bool> isSignedIn() async => false;
  @override
  Future<bool> signIn() async => false;
  @override
  Future<void> signInSilently() async {}
  @override
  Future<void> signOut() async {}
  @override
  String? get userEmail => null;
  @override
  String? get userId => null;
}

class _NoCloudOrchestrator implements BackupOrchestrator {
  @override
  Future<BackupResult> createBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async => const BackupResult(success: false);
  @override
  Future<BackupFileInfo?> getCloudBackupInfo() async => null;
  @override
  Future<RestoreResult> restoreBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async => const RestoreResult(success: false);
  @override
  GoogleAuthService get authService => throw UnimplementedError();
  @override
  DriveBackupService get driveService => throw UnimplementedError();
  @override
  BackupEncryptionService get encryptionService => throw UnimplementedError();
  @override
  Isar get isar => throw UnimplementedError();
  @override
  IsarExportService get exportService => throw UnimplementedError();
}
