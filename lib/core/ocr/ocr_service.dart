/// Reads text out of a receipt image.
///
/// Phase 1 ships [NoopOcrService]: receipt scanning is off, and on-device OCR
/// (Google ML Kit) was removed because its native models cost ~15 MB per ABI and
/// broke the iOS CocoaPods build. Phase 2 swaps in an ML Kit implementation — see
/// "Restoring receipt OCR (Phase 2)" in CONTRIBUTING.md and docs/phase2/.
abstract class OcrService {
  /// Recognised text, or null if there is none.
  Future<String?> extractTextFromImage(String imagePath);

  Future<void> dispose();
}

/// Phase 1: recognises nothing, so the scanner reports "text not found".
class NoopOcrService implements OcrService {
  const NoopOcrService();

  @override
  Future<String?> extractTextFromImage(String imagePath) async => null;

  @override
  Future<void> dispose() async {}
}
