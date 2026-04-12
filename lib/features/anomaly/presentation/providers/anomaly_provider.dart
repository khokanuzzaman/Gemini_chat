// Feature: Anomaly
// Layer: Presentation

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../data/services/anomaly_detection_service.dart';
import '../../domain/entities/anomaly_alert.dart';

/// Incremented by mutation paths that change anomaly inputs beyond
/// normal expense save/delete flow — specifically category rename/delete,
/// demo-seed, and clear-all-data. Bumping this forces AnomalyNotifier.build
/// to re-run detection instead of using cached alerts.
final anomalyForceRedetectTokenProvider = StateProvider<int>((ref) => 0);

class AnomalyState {
  const AnomalyState({
    required this.alerts,
    required this.isDetecting,
    this.lastDetected,
  });

  final List<AnomalyAlert> alerts;
  final bool isDetecting;
  final DateTime? lastDetected;

  AnomalyState copyWith({
    List<AnomalyAlert>? alerts,
    bool? isDetecting,
    DateTime? lastDetected,
    bool clearLastDetected = false,
  }) {
    return AnomalyState(
      alerts: alerts ?? this.alerts,
      isDetecting: isDetecting ?? this.isDetecting,
      lastDetected: clearLastDetected
          ? null
          : (lastDetected ?? this.lastDetected),
    );
  }

  List<AnomalyAlert> get activeAlerts =>
      alerts.where((alert) => !alert.isDismissed).toList(growable: false);

  List<AnomalyAlert> get dismissedAlerts =>
      alerts.where((alert) => alert.isDismissed).toList(growable: false);

  int get highSeverityCount => activeAlerts
      .where((alert) => alert.severity == AnomalySeverity.high)
      .length;

  int get mediumSeverityCount => activeAlerts
      .where((alert) => alert.severity == AnomalySeverity.medium)
      .length;

  int get lowSeverityCount => activeAlerts
      .where((alert) => alert.severity == AnomalySeverity.low)
      .length;
}

final anomalyProvider = NotifierProvider<AnomalyNotifier, AnomalyState>(
  AnomalyNotifier.new,
);

class AnomalyNotifier extends Notifier<AnomalyState> {
  static const _cacheKey = 'anomaly_alerts_v2';
  static const _lastDetectedKey = 'anomaly_last_detected_v2';
  static const _lastHighSignatureKey = 'anomaly_last_high_signature_v2';
  Future<void>? _inFlightDetection;
  int? _lastSeenRefreshToken;
  int? _lastSeenForceToken;
  bool _queuedDetection = false;

  @override
  AnomalyState build() {
    final refreshToken = ref.watch(expenseRefreshTokenProvider);
    final forceToken = ref.watch(anomalyForceRedetectTokenProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final isFirstBuild = _lastSeenRefreshToken == null;
    final refreshTokenChanged = _lastSeenRefreshToken != refreshToken;
    final forceTokenChanged = _lastSeenForceToken != forceToken;

    _lastSeenRefreshToken = refreshToken;
    _lastSeenForceToken = forceToken;

    final cachedAlerts = _decodeAlerts(prefs.getString(_cacheKey));
    final lastDetected = _decodeDate(prefs.getInt(_lastDetectedKey));

    if (forceTokenChanged && !isFirstBuild) {
      Future.microtask(detect);
    } else if (refreshTokenChanged && !isFirstBuild) {
      Future.microtask(detect);
    } else {
      Future.microtask(detectIfNeeded);
    }

    return AnomalyState(
      alerts: cachedAlerts,
      isDetecting: false,
      lastDetected: lastDetected,
    );
  }

  /// Detects anomalies if the cached snapshot is older than 6 hours.
  Future<void> detectIfNeeded() async {
    final lastDetected = state.lastDetected;
    if (lastDetected == null ||
        DateTime.now().difference(lastDetected) >= const Duration(hours: 6)) {
      await detect();
    }
  }

  /// Runs anomaly detection over the last 30 days vs previous 90 days.
  Future<void> detect() async {
    if (_inFlightDetection != null) {
      _queuedDetection = true;
      await _inFlightDetection;
      if (_queuedDetection) {
        _queuedDetection = false;
        await detect();
      }
      return;
    }

    do {
      _queuedDetection = false;
      final future = _performDetect();
      _inFlightDetection = future;
      try {
        await future;
      } finally {
        _inFlightDetection = null;
      }
    } while (_queuedDetection);
  }

  Future<void> _performDetect() async {
    state = state.copyWith(isDetecting: true);

    final now = DateTime.now();
    final expenses = await ref.read(expenseRepositoryProvider).getAllExpenses();
    final last30Start = now.subtract(const Duration(days: 30));
    final previous90Start = now.subtract(const Duration(days: 120));
    final previous90End = now.subtract(const Duration(days: 30));

    final last30 = expenses
        .where((expense) => !expense.date.isBefore(last30Start))
        .toList(growable: false);
    final previous90 = expenses
        .where(
          (expense) =>
              !expense.date.isBefore(previous90Start) &&
              expense.date.isBefore(previous90End),
        )
        .toList(growable: false);

    final alerts = const AnomalyDetectionService().detect(
      last30Days: last30,
      previous90Days: previous90,
    );

    final detectedAt = DateTime.now();
    state = AnomalyState(
      alerts: alerts,
      isDetecting: false,
      lastDetected: detectedAt,
    );

    await _persistState();
    await _notifyHighSeverity(state.activeAlerts);
  }

  Future<void> reDetect() async {
    await detect();
  }

  Future<void> dismiss(int alertId) async {
    state = state.copyWith(
      alerts: [
        for (final alert in state.alerts)
          if (alert.id == alertId) alert.copyWith(isDismissed: true) else alert,
      ],
    );
    await _persistState();
  }

  Future<void> dismissAll() async {
    state = state.copyWith(
      alerts: [
        for (final alert in state.alerts) alert.copyWith(isDismissed: true),
      ],
    );
    await _persistState();
  }

  Future<List<AnomalyAlert>> getActiveAlerts() async {
    await detectIfNeeded();
    return state.activeAlerts;
  }

  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastDetectedKey);
    await prefs.remove(_lastHighSignatureKey);

    _lastSeenRefreshToken = null;
    _lastSeenForceToken = null;
    _queuedDetection = false;
    state = const AnomalyState(
      alerts: [],
      isDetecting: false,
      lastDetected: null,
    );
  }

  Future<void> _persistState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _cacheKey,
      jsonEncode(state.alerts.map((alert) => alert.toJson()).toList()),
    );
    if (state.lastDetected != null) {
      await prefs.setInt(
        _lastDetectedKey,
        state.lastDetected!.millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _notifyHighSeverity(List<AnomalyAlert> alerts) async {
    final highAlert = alerts
        .where((alert) => alert.severity == AnomalySeverity.high)
        .firstOrNull;
    if (highAlert == null) {
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final signature =
        '${highAlert.type.name}_${highAlert.category}_${highAlert.currentAmount.toStringAsFixed(0)}_${highAlert.relatedDate?.toIso8601String() ?? ''}';
    if (prefs.getString(_lastHighSignatureKey) == signature) {
      return;
    }

    await NotificationService.showAnomalyAlert(
      category: highAlert.category,
      message: highAlert.message,
      percentage: (highAlert.ratio - 1) * 100,
    );
    await prefs.setString(_lastHighSignatureKey, signature);
  }

  List<AnomalyAlert> _decodeAlerts(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => AnomalyAlert.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  DateTime? _decodeDate(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null || millisecondsSinceEpoch <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
