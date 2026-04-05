// Feature: Split
// Layer: Data

import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/split/domain/entities/split_bill_entity.dart';

part 'split_bill_model.g.dart';

@collection
class SplitBillModel {
  Id id = Isar.autoIncrement;

  late String title;
  late double totalAmount;
  late String personsJson;
  @Index()
  late DateTime date;
  String? notes;
  late bool isSettled;
  late String category;

  SplitBillEntity toEntity() {
    final persons = <SplitPerson>[];
    try {
      final decoded = jsonDecode(personsJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            persons.add(SplitPerson.fromJson(item));
          } else if (item is Map) {
            persons.add(SplitPerson.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (_) {
      // Keep empty if legacy/corrupted data cannot be parsed.
    }

    return SplitBillEntity(
      id: id,
      title: title,
      totalAmount: totalAmount,
      persons: persons,
      date: date,
      notes: notes,
      isSettled: isSettled,
      category: category,
    );
  }

  static SplitBillModel fromEntity(SplitBillEntity entity) {
    return SplitBillModel()
      ..id = entity.id > 0 ? entity.id : Isar.autoIncrement
      ..title = entity.title
      ..totalAmount = entity.totalAmount
      ..personsJson = jsonEncode(
        entity.persons.map((person) => person.toJson()).toList(growable: false),
      )
      ..date = entity.date
      ..notes = entity.notes
      ..isSettled = entity.isSettled
      ..category = entity.category;
  }
}
