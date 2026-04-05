// Feature: Anomaly
// Layer: Domain

import 'package:flutter/material.dart';

enum AnomalyType {
  categorySpike,
  largeTransaction,
  dailySpike,
  frequencyIncrease,
}

enum AnomalySeverity { low, medium, high }

extension AnomalySeverityExt on AnomalySeverity {
  Color get color {
    return switch (this) {
      AnomalySeverity.low => Colors.amber.shade700,
      AnomalySeverity.medium => Colors.orange.shade700,
      AnomalySeverity.high => Colors.red.shade700,
    };
  }

  IconData get icon {
    return switch (this) {
      AnomalySeverity.low => Icons.info_outline,
      AnomalySeverity.medium => Icons.warning_amber_outlined,
      AnomalySeverity.high => Icons.warning_rounded,
    };
  }

  String get label {
    return switch (this) {
      AnomalySeverity.low => 'সামান্য বেশি',
      AnomalySeverity.medium => 'উল্লেখযোগ্য',
      AnomalySeverity.high => 'অনেক বেশি',
    };
  }
}

class AnomalyAlert {
  const AnomalyAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.category,
    required this.currentAmount,
    required this.normalAmount,
    required this.ratio,
    required this.message,
    required this.detectedAt,
    this.relatedDate,
    this.isDismissed = false,
  });

  final int id;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String category;
  final double currentAmount;
  final double normalAmount;
  final double ratio;
  final String message;
  final DateTime detectedAt;
  final DateTime? relatedDate;
  final bool isDismissed;

  AnomalyAlert copyWith({
    int? id,
    AnomalyType? type,
    AnomalySeverity? severity,
    String? category,
    double? currentAmount,
    double? normalAmount,
    double? ratio,
    String? message,
    DateTime? detectedAt,
    DateTime? relatedDate,
    bool? isDismissed,
  }) {
    return AnomalyAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      currentAmount: currentAmount ?? this.currentAmount,
      normalAmount: normalAmount ?? this.normalAmount,
      ratio: ratio ?? this.ratio,
      message: message ?? this.message,
      detectedAt: detectedAt ?? this.detectedAt,
      relatedDate: relatedDate ?? this.relatedDate,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'category': category,
      'currentAmount': currentAmount,
      'normalAmount': normalAmount,
      'ratio': ratio,
      'message': message,
      'detectedAt': detectedAt.toIso8601String(),
      'relatedDate': relatedDate?.toIso8601String(),
      'isDismissed': isDismissed,
    };
  }

  factory AnomalyAlert.fromJson(Map<String, dynamic> json) {
    return AnomalyAlert(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: AnomalyType.values.byName(
        json['type']?.toString() ?? AnomalyType.dailySpike.name,
      ),
      severity: AnomalySeverity.values.byName(
        json['severity']?.toString() ?? AnomalySeverity.low.name,
      ),
      category: json['category']?.toString() ?? '',
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      normalAmount: (json['normalAmount'] as num?)?.toDouble() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 1,
      message: json['message']?.toString() ?? '',
      detectedAt:
          DateTime.tryParse(json['detectedAt']?.toString() ?? '') ??
          DateTime.now(),
      relatedDate: DateTime.tryParse(json['relatedDate']?.toString() ?? ''),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}
