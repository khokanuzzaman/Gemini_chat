import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/chat_repository.dart';

class SendVoiceMessageUseCase {
  const SendVoiceMessageUseCase(this._repository);

  final ChatRepository _repository;

  Stream<Either<Failure, String>> call(
    String audioFilePath, {
    bool useRag = true,
  }) {
    return _repository.sendVoiceMessage(audioFilePath, useRag: useRag);
  }
}
