import '../../domain/entities/message_entity.dart';

String buildChatMessageKey(MessageEntity message) {
  return message.id != null
      ? 'id:${message.id}'
      : '${message.createdAt.microsecondsSinceEpoch}:${message.text.hashCode}:${message.isUser ? 1 : 0}';
}
