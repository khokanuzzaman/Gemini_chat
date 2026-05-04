import '../../domain/entities/message_entity.dart';

String buildChatMessageKey(MessageEntity message) {
  final normalizedText = message.text.trim();
  return '${message.createdAt.microsecondsSinceEpoch}:'
      '${message.isUser ? 1 : 0}:'
      '${_stableHash(normalizedText)}';
}

int _stableHash(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
