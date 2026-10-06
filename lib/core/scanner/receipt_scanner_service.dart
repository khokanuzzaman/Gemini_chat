import '../ocr/ocr_service.dart';
import 'receipt_format_checker.dart';
import 'receipt_image_preprocessor.dart';
import 'receipt_image_source.dart';
import 'scan_result.dart';

/// Pick a receipt image -> auto-crop -> OCR -> check it looks like a receipt.
///
/// Platform specifics (camera/gallery + permissions, ML Kit) live behind
/// [ReceiptImageSource] and [OcrService], so this pipeline is plain Dart and
/// unit-testable. Phase 1 wires the no-op implementations of both.
class ReceiptScannerService {
  ReceiptScannerService({
    required OcrService ocrService,
    required ReceiptImageSource imageSource,
    ReceiptImagePreprocessor? imagePreprocessor,
    ReceiptFormatChecker? formatChecker,
  }) : _ocrService = ocrService,
       _imageSource = imageSource,
       _imagePreprocessor =
           imagePreprocessor ?? const ReceiptImagePreprocessor(),
       _formatChecker = formatChecker ?? const ReceiptFormatChecker();

  final OcrService _ocrService;
  final ReceiptImageSource _imageSource;
  final ReceiptImagePreprocessor _imagePreprocessor;
  final ReceiptFormatChecker _formatChecker;

  Future<ScanResult> pickAndScanFromCamera() async {
    return _scan(await _imageSource.pickFromCamera());
  }

  Future<ScanResult> pickAndScanFromGallery() async {
    return _scan(await _imageSource.pickFromGallery());
  }

  Future<ScanResult> _scan(ReceiptImagePick pick) async {
    final path = pick.imagePath;
    if (path == null) {
      return ScanResult.failure(pick.error ?? 'unavailable');
    }
    return _processImage(path);
  }

  Future<ScanResult> _processImage(String imagePath) async {
    final processedImage = await _imagePreprocessor.autoCrop(imagePath);
    final extractedText = await _ocrService.extractTextFromImage(
      processedImage.path,
    );
    if (extractedText == null || extractedText.trim().length < 20) {
      return ScanResult.failure(
        'text_not_found',
        wasAutoCropped: processedImage.wasAutoCropped,
      );
    }

    final formatCheck = _formatChecker.check(extractedText);
    if (!formatCheck.isLikelyReceipt) {
      return ScanResult.failure(
        'invalid_format',
        score: formatCheck.score,
        warnings: formatCheck.warnings,
        wasAutoCropped: processedImage.wasAutoCropped,
      );
    }

    return ScanResult.success(
      text: extractedText,
      score: formatCheck.score,
      warnings: formatCheck.warnings,
      wasAutoCropped: processedImage.wasAutoCropped,
    );
  }
}
