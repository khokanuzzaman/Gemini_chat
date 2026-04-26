class SmsMessage {
  const SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    this.threadId,
  });

  final int id;
  final String address;
  final String body;
  final DateTime date;
  final int? threadId;

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: _toInt(map['id']),
      address: (map['address'] as String? ?? '').trim(),
      body: (map['body'] as String? ?? '').trim(),
      date: DateTime.fromMillisecondsSinceEpoch(_toInt(map['date'])),
      threadId: map['threadId'] == null ? null : _toInt(map['threadId']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date.millisecondsSinceEpoch,
      'threadId': threadId,
    };
  }

  SmsMessage copyWith({
    int? id,
    String? address,
    String? body,
    DateTime? date,
    Object? threadId = _smsMessageUnset,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      address: address ?? this.address,
      body: body ?? this.body,
      date: date ?? this.date,
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
