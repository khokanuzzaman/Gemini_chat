import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/chat_repository.dart';

class ScanReceiptUseCase {
  const ScanReceiptUseCase(this._repository);

  final ChatRepository _repository;

  Stream<Either<Failure, String>> call(String extractedText) {
    return _repository.sendReceiptText(extractedText);
  }
}
