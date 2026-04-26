import 'dart:io';

import 'package:flutter/services.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/sms_message_entity.dart';

class AndroidSmsReaderService {
  AndroidSmsReaderService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'pocketpilot_ai/sms_reader';

  final MethodChannel _channel;

  bool get isSupported => Platform.isAndroid;

  Future<List<SmsMessageEntity>> readInboxMessages({
    int limit = 200,
    DateTime? since,
    DateTime? before,
    int? beforeMessageId,
  }) async {
    if (!isSupported) {
      throw const GeneralException('SMS অটো-ইমপোর্ট শুধু Android-এ কাজ করে।');
    }

    try {
      final request = {
        'limit': limit.clamp(1, 500),
        ...?_optionalEntry('sinceMillis', since?.millisecondsSinceEpoch),
        ...?_optionalEntry('beforeMillis', before?.millisecondsSinceEpoch),
        ...?_optionalEntry('beforeMessageId', beforeMessageId),
      };
      final response = await _channel
          .invokeMethod<List<dynamic>>('getInboxMessages', request);

      final messages = (response ?? const <dynamic>[])
          .map(_normalizeMap)
          .map(SmsMessageEntity.fromMap)
          .where((message) => message.body.isNotEmpty)
          .toList(growable: false);
      messages.sort(
        (first, second) => second.receivedAt.compareTo(first.receivedAt),
      );
      return messages;
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        throw const PermissionDeniedException('SMS পড়ার অনুমতি দিন।');
      }
      throw GeneralException(error.message ?? 'SMS ইনবক্স পড়া যায়নি।');
    }
  }

  Map<String, dynamic> _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  Map<String, Object>? _optionalEntry(String key, Object? value) {
    if (value == null) {
      return null;
    }
    return {key: value};
  }
}
