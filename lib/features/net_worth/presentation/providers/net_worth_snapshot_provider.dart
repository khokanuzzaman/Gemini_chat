import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../data/net_worth_snapshot_service.dart';

final netWorthSnapshotServiceProvider = Provider<NetWorthSnapshotService>((
  ref,
) {
  return NetWorthSnapshotService(isar: ref.watch(isarProvider));
});
