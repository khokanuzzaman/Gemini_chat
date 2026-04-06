// Feature: Goals
// Layer: Domain

import 'package:flutter/material.dart';

enum GoalStatus { active, achieved, cancelled }

class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.createdAt,
    required this.status,
    this.notes,
  });

  final int id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final GoalStatus status;
  final String? notes;

  double get progressPercentage {
    if (savedAmount == 0 || targetAmount <= 0) {
      return 0;
    }
    return (savedAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  double get remainingAmount {
    return (targetAmount - savedAmount).clamp(0.0, double.infinity);
  }

  bool get isAchieved => savedAmount >= targetAmount && targetAmount > 0;

  int get daysRemaining {
    return targetDate.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  double get requiredMonthlySaving {
    if (daysRemaining <= 0) {
      return remainingAmount;
    }
    final monthsLeft = daysRemaining / 30.0;
    if (monthsLeft <= 0) {
      return remainingAmount;
    }
    return remainingAmount / monthsLeft;
  }

  double get dailyProgress {
    final daysPassed = DateTime.now().difference(createdAt).inDays + 1;
    return daysPassed <= 0 ? savedAmount : savedAmount / daysPassed;
  }

  bool get isOnTrack {
    if (daysRemaining <= 0) {
      return isAchieved;
    }
    final totalDays = targetDate.difference(createdAt).inDays;
    if (totalDays <= 0) {
      return isAchieved;
    }
    final elapsedDays = DateTime.now()
        .difference(createdAt)
        .inDays
        .clamp(0, totalDays);
    final expectedProgress = elapsedDays / totalDays;
    final actualProgress = progressPercentage / 100;
    return actualProgress >= expectedProgress * 0.85;
  }

  Color get statusColor {
    if (isAchieved || status == GoalStatus.achieved) {
      return Colors.green;
    }
    if (!isOnTrack) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  GoalEntity copyWith({
    int? id,
    String? title,
    String? emoji,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    GoalStatus? status,
    String? notes,
    bool clearNotes = false,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
