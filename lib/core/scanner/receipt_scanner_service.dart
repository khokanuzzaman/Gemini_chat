import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../mlkit/ocr_service.dart';
import 'receipt_format_checker.dart';
import 'receipt_image_preprocessor.dart';
import 'scan_result.dart';

class ReceiptScannerService {
  ReceiptScannerService({
    required OcrService ocrService,
    ReceiptImagePreprocessor? imagePreprocessor,
    ReceiptFormatChecker? formatChecker,
    ImagePicker? picker,
  }) : _ocrService = ocrService,
       _imagePreprocessor =
           imagePreprocessor ?? const ReceiptImagePreprocessor(),
       _formatChecker = formatChecker ?? const ReceiptFormatChecker(),
       _picker = picker ?? ImagePicker();

  final OcrService _ocrService;
  final ReceiptImagePreprocessor _imagePreprocessor;
  final ReceiptFormatChecker _formatChecker;
  final ImagePicker _picker;

  Future<ScanResult> pickAndScanFromCamera() async {
    final granted = await Permission.camera.request();
    if (!granted.isGranted) {
      return const ScanResult.failure('permission_denied');
    }

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image == null) {
      return const ScanResult.failure('cancelled');
    }

    return _processImage(image.path);
  }

  Future<ScanResult> pickAndScanFromGallery() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        return const ScanResult.failure('permission_denied');
      }
    }

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image == null) {
      return const ScanResult.failure('cancelled');
    }

    return _processImage(image.path);
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
