import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/ocr/ocr_service.dart';
import 'package:gemini_chat/core/scanner/receipt_image_source.dart';
import 'package:gemini_chat/core/scanner/receipt_scanner_service.dart';

const _receiptText = '''
Shwapno Super Shop
Invoice #4521  06/10/2026
Rice 5kg  Tk 450.00
Oil 1L  Tk 210.00
VAT 15%  Tk 99.00
Total Tk 759.00
Cash Tk 800.00
''';

class _FixedSource implements ReceiptImageSource {
  _FixedSource(this.pick);
  final ReceiptImagePick pick;
  int calls = 0;

  @override
  Future<ReceiptImagePick> pickFromCamera() async {
    calls++;
    return pick;
  }

  @override
  Future<ReceiptImagePick> pickFromGallery() async {
    calls++;
    return pick;
  }
}

class _FixedOcr implements OcrService {
  _FixedOcr(this.text);
  final String? text;
  String? lastPath;

  @override
  Future<String?> extractTextFromImage(String imagePath) async {
    lastPath = imagePath;
    return text;
  }

  @override
  Future<void> dispose() async {}
}

ReceiptScannerService _scanner(OcrService ocr, ReceiptImageSource source) {
  return ReceiptScannerService(ocrService: ocr, imageSource: source);
}

void main() {
  group('Phase 1 wiring (no-op OCR + no-op image source)', () {
    test('NoopOcrService recognises nothing', () async {
      expect(
        await const NoopOcrService().extractTextFromImage('/x.jpg'),
        isNull,
      );
      await const NoopOcrService().dispose(); // must not throw
    });

    test('the real Phase 1 pair fails cleanly instead of crashing', () async {
      final scanner = _scanner(
        const NoopOcrService(),
        const NoopReceiptImageSource(),
      );
      final camera = await scanner.pickAndScanFromCamera();
      final gallery = await scanner.pickAndScanFromGallery();

      expect(camera.success, isFalse);
      expect(camera.error, 'unavailable');
      expect(gallery.error, 'unavailable');
    });

    test('with an image but the no-op OCR: "text_not_found"', () async {
      final scanner = _scanner(
        const NoopOcrService(),
        _FixedSource(const ReceiptImagePick.path('/does/not/exist.jpg')),
      );
      expect((await scanner.pickAndScanFromGallery()).error, 'text_not_found');
    });
  });

  group('the pipeline Phase 2 will plug real implementations into', () {
    test('image + receipt text -> success, OCR got the image path', () async {
      final ocr = _FixedOcr(_receiptText);
      final scanner = _scanner(
        ocr,
        _FixedSource(const ReceiptImagePick.path('/does/not/exist.jpg')),
      );

      final result = await scanner.pickAndScanFromCamera();

      expect(result.success, isTrue);
      expect(result.text, _receiptText);
      expect(ocr.lastPath, '/does/not/exist.jpg');
    });

    test(
      'source failures (cancelled / permission_denied) pass straight through',
      () async {
        for (final code in ['cancelled', 'permission_denied']) {
          final ocr = _FixedOcr(_receiptText);
          final scanner = _scanner(
            ocr,
            _FixedSource(ReceiptImagePick.failure(code)),
          );
          final result = await scanner.pickAndScanFromCamera();
          expect(result.error, code);
          expect(
            ocr.lastPath,
            isNull,
            reason: 'OCR must not run without an image',
          );
        }
      },
    );

    test(
      'short text -> text_not_found; non-receipt text -> invalid_format',
      () async {
        final source = _FixedSource(const ReceiptImagePick.path('/x.jpg'));
        expect(
          (await _scanner(
            _FixedOcr('hi'),
            source,
          ).pickAndScanFromGallery()).error,
          'text_not_found',
        );
        expect(
          (await _scanner(
            _FixedOcr('the quick brown fox jumps over the lazy dog'),
            source,
          ).pickAndScanFromGallery()).error,
          'invalid_format',
        );
      },
    );
  });
}
