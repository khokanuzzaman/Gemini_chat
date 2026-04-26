class SmsMessageEntity {
  const SmsMessageEntity({
    required this.id,
    required this.address,
    required this.body,
    required this.receivedAt,
    this.threadId,
  });

  final int id;
  final String address;
  final String body;
  final DateTime receivedAt;
  final int? threadId;

  factory SmsMessageEntity.fromMap(Map<String, dynamic> map) {
    return SmsMessageEntity(
      id: _toInt(map['id']),
      address: (map['address'] as String? ?? '').trim(),
      body: (map['body'] as String? ?? '').trim(),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(_toInt(map['date'])),
      threadId: map['threadId'] == null ? null : _toInt(map['threadId']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': receivedAt.millisecondsSinceEpoch,
      'threadId': threadId,
    };
  }

  SmsMessageEntity copyWith({
    int? id,
    String? address,
    String? body,
    DateTime? receivedAt,
    Object? threadId = _smsMessageUnset,
  }) {
    return SmsMessageEntity(
      id: id ?? this.id,
      address: address ?? this.address,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      threadId: threadId == _smsMessageUnset ? this.threadId : threadId as int?,
    );
  }
}

const _smsMessageUnset = Object();

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
