import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/chat/domain/entities/message_entity.dart';
import 'package:gemini_chat/features/chat/presentation/utils/message_key.dart';

void main() {
  test(
    'buildChatMessageKey stays stable after a persisted id is assigned',
    () {
      final createdAt = DateTime(2026, 5, 4, 10, 30, 15, 123, 456);
      final draftMessage = MessageEntity(
        text: '[{"expenses":[],"incomes":[]}]',
        isUser: false,
        createdAt: createdAt,
      );
      final persistedMessage = MessageEntity(
        id: 42,
        text: '[{"expenses":[],"incomes":[]}]',
        isUser: false,
        createdAt: createdAt,
      );

      expect(
        buildChatMessageKey(persistedMessage),
        buildChatMessageKey(draftMessage),
      );
    },
  );
}
