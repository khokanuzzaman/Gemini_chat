// Feature: Split
// Layer: Domain

import 'dart:math' as math;

class SplitPerson {
  const SplitPerson({
    required this.name,
    required this.amountPaid,
    required this.shareAmount,
  });

  final String name;
  final double amountPaid;
  final double shareAmount;

  double get balance => amountPaid - shareAmount;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amountPaid': amountPaid,
      'shareAmount': shareAmount,
    };
  }

  factory SplitPerson.fromJson(Map<String, dynamic> json) {
    return SplitPerson(
      name: json['name']?.toString() ?? '',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      shareAmount: (json['shareAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  SplitPerson copyWith({
    String? name,
    double? amountPaid,
    double? shareAmount,
  }) {
    return SplitPerson(
      name: name ?? this.name,
      amountPaid: amountPaid ?? this.amountPaid,
      shareAmount: shareAmount ?? this.shareAmount,
    );
  }
}

class SettlementSuggestion {
  const SettlementSuggestion({
    required this.from,
    required this.to,
    required this.amount,
  });

  final String from;
  final String to;
  final double amount;
}

class SplitBillEntity {
  const SplitBillEntity({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.persons,
    required this.date,
    this.notes,
    required this.isSettled,
    required this.category,
  });

  final int id;
  final String title;
  final double totalAmount;
  final List<SplitPerson> persons;
  final DateTime date;
  final String? notes;
  final bool isSettled;
  final String category;

  double get perPersonShare => persons.isEmpty ? 0 : totalAmount / persons.length;

  List<SettlementSuggestion> get settlements {
    final creditors = persons
        .where((person) => person.balance > 0.01)
        .map((person) => _MutableBalance(person.name, person.balance))
        .toList(growable: false);
    final debtors = persons
        .where((person) => person.balance < -0.01)
        .map((person) => _MutableBalance(person.name, person.balance.abs()))
        .toList(growable: false);

    final suggestions = <SettlementSuggestion>[];
    for (final debtor in debtors) {
      var remaining = debtor.amount;
      for (final creditor in creditors) {
        if (remaining <= 0.01) {
          break;
        }
        if (creditor.amount <= 0.01) {
          continue;
        }
        final amount = _roundMoney(math.min(remaining, creditor.amount));
        if (amount <= 0.01) {
          continue;
        }
        suggestions.add(
          SettlementSuggestion(from: debtor.name, to: creditor.name, amount: amount),
        );
        remaining = _roundMoney(remaining - amount);
        creditor.amount = _roundMoney(creditor.amount - amount);
      }
    }

    return suggestions;
  }

  SplitBillEntity copyWith({
    int? id,
    String? title,
    double? totalAmount,
    List<SplitPerson>? persons,
    DateTime? date,
    String? notes,
    bool? isSettled,
    String? category,
  }) {
    return SplitBillEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      persons: persons ?? this.persons,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isSettled: isSettled ?? this.isSettled,
      category: category ?? this.category,
    );
  }

  static double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}

class _MutableBalance {
  _MutableBalance(this.name, this.amount);

  final String name;
  double amount;
}
