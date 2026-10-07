// The user-facing side of "অ্যাকাউন্ট মুছুন": the confirm dialog (with the Drive
// checkbox), what it passes to the service, and what the user sees on success,
// cancel and failure.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/auth/account_deletion_service.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/settings/account_deletion_flow.dart';

class _Fake {
  _Fake({this.result = const AccountDeletionResult.success()});
  AccountDeletionResult result;
  final calls = <bool>[];

  AccountDeletionService build(WidgetRef _) => _Service(this);
}

class _Service extends AccountDeletionService {
  _Service(this.fake)
    : super(
        currentUid: () => 'u',
        deleteDriveBackups: () async {},
        deleteUserDocs: (_) async {},
        deleteAuthUser: () async {},
        reauthenticate: () async {},
        signOut: () async {},
        wipeLocal: () async {},
      );
  final _Fake fake;

  @override
  Future<AccountDeletionResult> delete({
    required bool deleteDriveBackup,
  }) async {
    fake.calls.add(deleteDriveBackup);
    return fake.result;
  }
}

Future<void> _open(
  WidgetTester tester,
  _Fake fake, {
  double width = 360,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => runAccountDeletionFlow(
                context,
                ref,
                serviceBuilder: fake.build,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dialog warns it is permanent and offers the Drive checkbox', (
    tester,
  ) async {
    await _open(tester, _Fake());
    expect(find.text('অ্যাকাউন্ট মুছে ফেলবেন?'), findsOneWidget);
    expect(find.textContaining('স্থায়ীভাবে মুছে যাবে'), findsOneWidget);
    expect(
      find.byKey(const Key('delete-account-drive-checkbox')),
      findsOneWidget,
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
  });

  testWidgets('cancel ("বাদ দিন") runs nothing', (tester) async {
    final fake = _Fake();
    await _open(tester, fake);
    await tester.tap(find.text('বাদ দিন'));
    await tester.pumpAndSettle();
    expect(fake.calls, isEmpty);
  });

  testWidgets('confirm with the checkbox on passes deleteDriveBackup: true', (
    tester,
  ) async {
    final fake = _Fake();
    await _open(tester, fake);
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(fake.calls, [true]);
  });

  testWidgets('unticking the checkbox passes deleteDriveBackup: false', (
    tester,
  ) async {
    final fake = _Fake();
    await _open(tester, fake);
    await tester.tap(find.byKey(const Key('delete-account-drive-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(fake.calls, [false]);
  });

  testWidgets('success: confirmation snackbar', (tester) async {
    await _open(tester, _Fake());
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('অ্যাকাউন্ট ও সব ডেটা মুছে ফেলা হয়েছে'), findsOneWidget);
  });

  testWidgets('failure: says why, and that the phone data is untouched', (
    tester,
  ) async {
    await _open(
      tester,
      _Fake(
        result: const AccountDeletionResult.failed(
          AccountDeletionStage.cloudData,
          'ইন্টারনেট সংযোগ নেই',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('অ্যাকাউন্ট মোছা যায়নি'), findsOneWidget);
    expect(find.textContaining('ইন্টারনেট সংযোগ নেই'), findsOneWidget);
    expect(find.textContaining('যেমন ছিল তেমনই আছে'), findsOneWidget);
    expect(find.text('অ্যাকাউন্ট ও সব ডেটা মুছে ফেলা হয়েছে'), findsNothing);
  });

  testWidgets('re-auth declined: a calm "not deleted" message', (tester) async {
    await _open(
      tester,
      _Fake(
        result: const AccountDeletionResult.failed(
          AccountDeletionStage.reauthentication,
          'আবার সাইন ইন করতে হবে। অ্যাকাউন্ট মোছা হয়নি।',
          cancelled: true,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('অ্যাকাউন্ট মোছা হয়নি'), findsOneWidget);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('dialogs do not overflow at ${width.toInt()} ×1.3', (
      tester,
    ) async {
      await _open(tester, _Fake(), width: width, scale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('delete-account-drive-checkbox')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
