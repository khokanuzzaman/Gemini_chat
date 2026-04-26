import 'package:isar_community/isar.dart';

part 'sms_ledger_sync_state_model.g.dart';

@collection
class SmsLedgerSyncStateModel {
  Id id = 1;

  bool initialBackfillComplete = false;

  @Index()
  DateTime? lastSuccessfulSyncAt;

  @Index()
  DateTime? lastSyncedSmsDate;

  int? lastSyncedSmsId;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
}
