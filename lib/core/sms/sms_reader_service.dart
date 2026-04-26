import 'dart:io';

import '../errors/exceptions.dart';
import '../../features/sms_import/data/services/android_sms_reader_service.dart';
import '../../features/sms_import/domain/entities/sms_message_entity.dart';
import 'sms_message.dart';
import 'sms_permission_handler.dart';

class SmsReaderService {
  SmsReaderService({
    AndroidSmsReaderService? readerService,
    SmsPermissionHandler? permissionHandler,
  }) : _readerService = readerService ?? AndroidSmsReaderService(),
       _permissionHandler = permissionHandler ?? const SmsPermissionHandler();

  final AndroidSmsReaderService _readerService;
  final SmsPermissionHandler _permissionHandler;

  Future<List<SmsMessage>> readSmsPage({
    int maxCount = 500,
    DateTime? since,
    DateTime? before,
    int? beforeMessageId,
  }) async {
    if (!Platform.isAndroid) {
      return const <SmsMessage>[];
    }

    final granted = await _permissionHandler.hasPermission();
    if (!granted) {
      throw const PermissionDeniedException('SMS পড়ার অনুমতি দিন।');
    }

    final messages = await _readerService.readInboxMessages(
      limit: maxCount.clamp(1, 500),
      since: since,
      before: before,
      beforeMessageId: beforeMessageId,
    );
    return messages.map(_fromEntity).toList(growable: false);
  }

  Future<List<SmsMessage>> readAllSms({
    int maxCount = 500,
    DateTime? since,
    DateTime? before,
    int? beforeMessageId,
  }) async {
    return readSmsPage(
      maxCount: maxCount,
      since: since,
      before: before,
      beforeMessageId: beforeMessageId,
    );
  }

  Future<List<SmsMessage>> readAllSmsByPaging({
    int pageSize = 500,
    DateTime? since,
  }) async {
    final collected = <SmsMessage>[];
    DateTime? before;
    int? beforeMessageId;

    while (true) {
      final page = await readSmsPage(
        maxCount: pageSize,
        since: since,
        before: before,
        beforeMessageId: beforeMessageId,
      );
      if (page.isEmpty) {
        break;
      }
      collected.addAll(page);
      if (page.length < pageSize) {
        break;
      }
      before = page.last.date;
      beforeMessageId = page.last.id;
    }

    return collected;
  }

  Future<List<SmsMessage>> readSmsSince(DateTime since) {
    return readAllSmsByPaging(since: since);
  }

  Future<List<SmsMessage>> readSmsFromSenders(
    List<String> senderIds, {
    DateTime? since,
  }) async {
    final normalizedSenders = senderIds
        .map((sender) => sender.trim().toLowerCase())
        .where((sender) => sender.isNotEmpty)
        .toSet();

    if (normalizedSenders.isEmpty) {
      return const <SmsMessage>[];
    }

    final messages = await readAllSmsByPaging(since: since);
    return messages
        .where(
          (message) =>
              normalizedSenders.contains(message.address.trim().toLowerCase()),
        )
        .toList(growable: false);
  }

  SmsMessage _fromEntity(SmsMessageEntity message) {
    return SmsMessage(
      id: message.id,
      address: message.address,
      body: message.body,
      date: message.receivedAt,
      threadId: message.threadId,
    );
  }
}
