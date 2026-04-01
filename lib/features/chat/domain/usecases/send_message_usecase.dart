import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Stream<Either<Failure, String>> call(
    List<MessageEntity> conversation, {
    bool useRag = true,
  }) {
    return _repository.sendMessage(conversation, useRag: useRag);
  }
}
