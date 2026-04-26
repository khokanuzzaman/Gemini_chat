import 'package:isar_community/isar.dart';

import '../database/models/imported_sms_model.dart';
import 'parsed_transaction.dart';
import 'sms_message.dart';
import 'sms_signature_codec.dart';

class SmsDuplicateDetector {
  SmsDuplicateDetector(this._isar, {SmsSignatureCodec? signatureCodec})
    : _signatureCodec = signatureCodec ?? const SmsSignatureCodec();

  final Isar _isar;
  final SmsSignatureCodec _signatureCodec;

  String generateSignature(SmsMessage sms) {
    return _signatureCodec.generateSignature(sms);
  }

  Future<bool> isDuplicate(SmsMessage sms) async {
    final signature = generateSignature(sms);
    return (await _loadKnownSignatures()).contains(signature);
  }

  Future<void> markImported(
    SmsMessage sms, {
    int? expenseId,
    int? incomeId,
  }) async {
    final signature = generateSignature(sms);
    if ((await _loadKnownSignatures()).contains(signature)) {
      return;
    }

    final model = ImportedSmsModel()
      ..signature = signature
      ..sender = sms.address
      ..smsDate = sms.date
      ..importedAt = DateTime.now()
      ..expenseId = expenseId
      ..incomeId = incomeId;

    await _isar.writeTxn(() async {
      await _isar.importedSmsModels.put(model);
    });
  }

  Future<void> markBatchImported(List<SmsMessage> messages) async {
    final now = DateTime.now();
    final existingSignatures = await _loadKnownSignatures();
    final seen = <String>{};
    final models = messages
        .where((sms) {
          final signature = generateSignature(sms);
          if (!seen.add(signature)) {
            return false;
          }
          return !existingSignatures.contains(signature);
        })
        .map(
          (sms) => ImportedSmsModel()
            ..signature = generateSignature(sms)
            ..sender = sms.address
            ..smsDate = sms.date
            ..importedAt = now,
        )
        .toList(growable: false);
    if (models.isEmpty) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.importedSmsModels.putAll(models);
    });
  }

  Future<int> getImportedCount() async {
    return _isar.importedSmsModels.count();
  }

  Future<DateTime?> getLastImportDate() async {
    final all = await _isar.importedSmsModels.where().findAll();
    if (all.isEmpty) {
      return null;
    }
    all.sort((first, second) => second.smsDate.compareTo(first.smsDate));
    return all.first.smsDate;
  }

  Future<List<ParsedTransaction>> filterNew(
    List<ParsedTransaction> transactions,
    List<SmsMessage> originalMessages,
  ) async {
    final importedSignatures = await _loadKnownSignatures();
    final messagesById = {
      for (final message in originalMessages) message.id: message,
    };
    final freshTransactions = <ParsedTransaction>[];
    final seenSignatures = <String>{};

    for (var index = 0; index < transactions.length; index++) {
      final transaction = transactions[index];
      final sms =
          messagesById[transaction.smsId] ??
          (index < originalMessages.length ? originalMessages[index] : null);
      if (sms == null) {
        freshTransactions.add(transaction);
        continue;
      }

      final signature = generateSignature(sms);
      if (!seenSignatures.add(signature)) {
        continue;
      }
      if (importedSignatures.contains(signature)) {
        continue;
      }
      freshTransactions.add(transaction);
    }

    return freshTransactions;
  }

  Future<Set<String>> _loadKnownSignatures() async {
    final all = await _isar.importedSmsModels.where().findAll();
    return all.map((item) => item.signature).toSet();
  }
}
