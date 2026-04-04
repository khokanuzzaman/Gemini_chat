import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityProvider = NotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<bool>? _subscription;

  @override
  bool build() {
    final service = ref.read(connectivityServiceProvider);
    Future<void>.microtask(() async {
      state = await service.isConnected();
    });
    _subscription = service.onConnectivityChanged.listen((isConnected) {
      state = isConnected;
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return true;
  }
}
