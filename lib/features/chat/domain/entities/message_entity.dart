import '../../../../core/ai/rag_response_parser.dart';

class MessageEntity {
  const MessageEntity({
    this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isReceipt = false,
    this.isVoice = false,
    this.usedRagContext = false,
    this.isRag = false,
    this.ragType,
    this.isError = false,
    this.promptTokenCount,
    this.outputTokenCount,
    this.totalTokenCount,
  });

  final int? id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isReceipt;
  final bool isVoice;
  final bool usedRagContext;
  final bool isRag;
  final RagResponseType? ragType;
  final bool isError;
  final int? promptTokenCount;
  final int? outputTokenCount;
  final int? totalTokenCount;
}
