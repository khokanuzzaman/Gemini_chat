import 'package:isar/isar.dart';

import '../../../features/wallet/domain/entities/wallet_entity.dart';

part 'wallet_model.g.dart';

@collection
class WalletModel {
  Id id = Isar.autoIncrement;

  late String name;
  @enumerated
  late WalletType type;
  late String emoji;
  late double initialBalance;
  late double currentBalance;
  String? accountNumber;
  String? note;
  late int sortOrder;
  bool isArchived = false;
  late DateTime createdAt;
  late DateTime updatedAt;

  WalletEntity toEntity() {
    return WalletEntity(
      id: id,
      name: name,
      type: type,
      emoji: emoji,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      accountNumber: accountNumber,
      note: note,
      sortOrder: sortOrder,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static WalletModel fromEntity(WalletEntity entity) {
    final model = WalletModel()
      ..name = entity.name
      ..type = entity.type
      ..emoji = entity.emoji
      ..initialBalance = entity.initialBalance
      ..currentBalance = entity.currentBalance
      ..accountNumber = entity.accountNumber
      ..note = entity.note
      ..sortOrder = entity.sortOrder
      ..isArchived = entity.isArchived
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
    if (entity.id > 0) {
      model.id = entity.id;
    }
    return model;
  }
}
