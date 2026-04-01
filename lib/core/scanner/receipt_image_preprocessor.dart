import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ReceiptImagePreprocessResult {
  const ReceiptImagePreprocessResult({
    required this.path,
    required this.wasAutoCropped,
  });

  final String path;
  final bool wasAutoCropped;
}

class ReceiptImagePreprocessor {
  const ReceiptImagePreprocessor();

  Future<ReceiptImagePreprocessResult> autoCrop(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      return ReceiptImagePreprocessResult(
        path: imagePath,
        wasAutoCropped: false,
      );
    }

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return ReceiptImagePreprocessResult(
        path: imagePath,
        wasAutoCropped: false,
      );
    }

    final analysisImage = decoded.width > 900
        ? img.copyResize(decoded, width: 900)
        : decoded;

    final borderBrightness = _measureBorderBrightness(analysisImage);
    final threshold = (borderBrightness + 18).clamp(185, 245).toInt();

    var minX = analysisImage.width;
    var minY = analysisImage.height;
    var maxX = -1;
    var maxY = -1;
    var matchCount = 0;

    for (var y = 0; y < analysisImage.height; y++) {
      for (var x = 0; x < analysisImage.width; x++) {
        final pixel = analysisImage.getPixel(x, y);
        final brightness = _brightness(pixel.r, pixel.g, pixel.b);
        final saturation = _saturation(pixel.r, pixel.g, pixel.b);
        if (brightness < threshold || saturation > 60) {
          continue;
        }

        matchCount += 1;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (matchCount < (analysisImage.width * analysisImage.height * 0.02)) {
      return ReceiptImagePreprocessResult(
        path: imagePath,
        wasAutoCropped: false,
      );
    }

    final cropWidth = maxX - minX + 1;
    final cropHeight = maxY - minY + 1;
    final areaRatio =
        (cropWidth * cropHeight) / (analysisImage.width * analysisImage.height);

    if (cropWidth <= 0 ||
        cropHeight <= 0 ||
        areaRatio < 0.15 ||
        areaRatio > 0.96) {
      return ReceiptImagePreprocessResult(
        path: imagePath,
        wasAutoCropped: false,
      );
    }

    final scaleX = decoded.width / analysisImage.width;
    final scaleY = decoded.height / analysisImage.height;
    final paddingX = (cropWidth * 0.04 * scaleX).round();
    final paddingY = (cropHeight * 0.04 * scaleY).round();

    final originX = ((minX * scaleX).round() - paddingX).clamp(
      0,
      decoded.width - 1,
    );
    final originY = ((minY * scaleY).round() - paddingY).clamp(
      0,
      decoded.height - 1,
    );
    final targetWidth = (((cropWidth * scaleX).round()) + paddingX * 2).clamp(
      1,
      decoded.width - originX,
    );
    final targetHeight = (((cropHeight * scaleY).round()) + paddingY * 2).clamp(
      1,
      decoded.height - originY,
    );

    if (targetWidth >= decoded.width * 0.98 &&
        targetHeight >= decoded.height * 0.98) {
      return ReceiptImagePreprocessResult(
        path: imagePath,
        wasAutoCropped: false,
      );
    }

    final cropped = img.copyCrop(
      decoded,
      x: originX,
      y: originY,
      width: targetWidth,
      height: targetHeight,
    );
    final outputDirectory = await getTemporaryDirectory();
    final outputPath =
        '${outputDirectory.path}/receipt_crop_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final croppedBytes = img.encodeJpg(cropped, quality: 90);
    await File(outputPath).writeAsBytes(croppedBytes, flush: true);

    return ReceiptImagePreprocessResult(path: outputPath, wasAutoCropped: true);
  }

  int _measureBorderBrightness(img.Image image) {
    final sampleWidth = (image.width * 0.05).clamp(1, 32).toInt();
    final sampleHeight = (image.height * 0.05).clamp(1, 32).toInt();
    var total = 0;
    var count = 0;

    void addPixel(int x, int y) {
      final pixel = image.getPixel(x, y);
      total += _brightness(pixel.r, pixel.g, pixel.b);
      count += 1;
    }

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < sampleWidth; x++) {
        addPixel(x, y);
      }
      for (var x = image.width - sampleWidth; x < image.width; x++) {
        addPixel(x, y);
      }
    }

    for (var y = 0; y < sampleHeight; y++) {
      for (var x = sampleWidth; x < image.width - sampleWidth; x++) {
        addPixel(x, y);
      }
    }

    for (var y = image.height - sampleHeight; y < image.height; y++) {
      for (var x = sampleWidth; x < image.width - sampleWidth; x++) {
        addPixel(x, y);
      }
    }

    return count == 0 ? 0 : (total / count).round();
  }

  int _brightness(num r, num g, num b) {
    return (0.299 * r + 0.587 * g + 0.114 * b).round();
  }

  int _saturation(num r, num g, num b) {
    final maxValue = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minValue = [r, g, b].reduce((a, b) => a < b ? a : b);
    return (maxValue - minValue).round();
  }
}
