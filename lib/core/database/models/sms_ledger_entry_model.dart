import 'package:isar_community/isar.dart';

import '../../sms/parsed_transaction.dart';
import '../../sms/sms_message.dart';

part 'sms_ledger_entry_model.g.dart';

@collection
class SmsLedgerEntryModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String signature;

  @Index()
  late int smsId;

  late String sender;
  late String rawMessage;

  @enumerated
  late ParsedTransactionSource source;

  @enumerated
  late ParsedTransactionDirection direction;

  @enumerated
  late ParsedTransactionKind kind;

  @enumerated
  late TransactionType type;

  late double amount;
  double? fee;
  double? balanceAfter;
  String? reference;
  String? counterparty;
  String? merchantName;
  String? accountMask;
  String? rawCategory;
  double confidence = 1;

  @Index()
  late DateTime occurredAt;

  @Index()
  late DateTime receivedAt;

  @Index()
  bool isImported = false;

  @Index()
  DateTime? importedAt;

  @Index()
  bool isIgnored = false;

  DateTime? ignoredAt;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  bool get isExpenseLike => type == TransactionType.expense;

  bool get isIncomeLike => type == TransactionType.income;

  bool get isTransferLike => type == TransactionType.transfer;

  bool get canImport => !isIgnored && !isImported && (isExpenseLike || isIncomeLike);

  String get displayTitle {
    final preferred = counterparty?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    final merchant = merchantName?.trim();
    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }
    final fallback = rawCategory?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return sender;
  }

  SmsMessage toSmsMessage() {
    return SmsMessage(
      id: smsId,
      address: sender,
      body: rawMessage,
      date: receivedAt,
    );
  }

  ParsedTransaction toParsedTransaction() {
    return ParsedTransaction(
      smsId: smsId,
      sender: sender,
      source: source,
      direction: direction,
      kind: kind,
      amount: amount,
      rawMessage: rawMessage,
      receivedAt: receivedAt,
      occurredAt: occurredAt,
      fee: fee,
      balanceAfter: balanceAfter,
      reference: reference,
      counterparty: counterparty,
      merchantName: merchantName,
      accountMask: accountMask,
      rawCategory: rawCategory,
      confidence: confidence,
    );
  }
}
