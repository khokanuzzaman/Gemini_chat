import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/auth/user_cloud_data.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  Future<void> seed(String uid) async {
    final user = firestore.collection('users').doc(uid);
    await user.set({'createdAt': 1});
    await user.collection('usage').doc('2026-10-05').set({'cloud_backup': 1});
    await user.collection('usage').doc('2026-10').set({'ai_budget': 2});
    await user.collection('subscription').doc('status').set({
      'isPremium': false,
    });
  }

  Future<int> docCount(String uid) async {
    final user = firestore.collection('users').doc(uid);
    final usage = await user.collection('usage').get();
    final sub = await user.collection('subscription').get();
    final self = await user.get();
    return usage.docs.length + sub.docs.length + (self.exists ? 1 : 0);
  }

  test('deletes every per-user doc and leaves other users alone', () async {
    await seed('u1');
    await seed('u2');
    expect(await docCount('u1'), 4);

    await UserCloudData(firestore).deleteAll('u1');

    expect(await docCount('u1'), 0);
    expect(await docCount('u2'), 4);
  });

  test('is idempotent and fine when there is nothing to delete', () async {
    final data = UserCloudData(firestore);
    await data.deleteAll('nobody');
    await seed('u1');
    await data.deleteAll('u1');
    await data.deleteAll('u1');
    expect(await docCount('u1'), 0);
  });

  test('pages through more docs than one batch', () async {
    final usage = firestore.collection('users').doc('u1').collection('usage');
    for (var i = 0; i < 950; i++) {
      await usage.doc('d$i').set({'n': i});
    }
    await UserCloudData(firestore).deleteAll('u1');
    expect((await usage.get()).docs, isEmpty);
  });

  test('covers every users/{uid}/<collection> path the app code writes', () {
    // Source scan: a NEW per-user collection added anywhere in lib/ without being
    // added to UserCloudData would survive account deletion — fail loudly instead.
    final path = RegExp(r'users/\$\{?\w+\}?/(\w+)');
    final found = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match in path.allMatches(entity.readAsStringSync())) {
        found.add(match.group(1)!);
      }
    }
    expect(
      found,
      isNotEmpty,
      reason: 'scan sanity: the known paths must be seen',
    );
    expect(UserCloudData.subcollections.toSet(), containsAll(found));
  });
}
