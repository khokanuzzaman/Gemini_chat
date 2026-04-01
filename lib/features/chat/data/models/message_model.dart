import 'package:isar/isar.dart';

import '../../../../core/ai/rag_response_parser.dart';
import '../../domain/entities/message_entity.dart';

part 'message_model.g.dart';

@collection
class MessageModel {
  Id id = Isar.autoIncrement;

  late String text;
  late bool isUser;
  bool isReceipt = false;
  bool isVoice = false;
  bool usedRagContext = false;
  bool isRag = false;
  String? ragType;
  bool isError = false;
  int? promptTokenCount;
  int? outputTokenCount;
  int? totalTokenCount;

  @Index()
  late DateTime createdAt;

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      text: text,
      isUser: isUser,
      isReceipt: isReceipt,
      isVoice: isVoice,
      createdAt: createdAt,
      usedRagContext: usedRagContext,
      isRag: isRag,
      ragType: _parseRagType(ragType),
      isError: isError,
      promptTokenCount: promptTokenCount,
      outputTokenCount: outputTokenCount,
      totalTokenCount: totalTokenCount,
    );
  }

  static MessageModel fromEntity(MessageEntity entity) {
    return MessageModel()
      ..id = entity.id ?? Isar.autoIncrement
      ..text = entity.text
      ..isUser = entity.isUser
      ..isReceipt = entity.isReceipt
      ..isVoice = entity.isVoice
      ..usedRagContext = entity.usedRagContext
      ..isRag = entity.isRag
      ..ragType = entity.ragType?.name
      ..isError = entity.isError
      ..promptTokenCount = entity.promptTokenCount
      ..outputTokenCount = entity.outputTokenCount
      ..totalTokenCount = entity.totalTokenCount
      ..createdAt = entity.createdAt;
  }

  static RagResponseType? _parseRagType(String? value) {
    if (value == null) {
      return null;
    }

    for (final type in RagResponseType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return null;
  }
}
