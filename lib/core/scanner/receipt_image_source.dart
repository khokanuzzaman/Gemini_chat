/// Where a receipt image comes from (camera or gallery), including the runtime
/// permission prompt for it.
///
/// Phase 1 ships [NoopReceiptImageSource] because the camera/photo plugins
/// (`image_picker`) and the CAMERA permission were removed along with ML Kit.
/// Phase 2 swaps in `ImagePickerReceiptSource` (docs/phase2/).
abstract class ReceiptImageSource {
  Future<ReceiptImagePick> pickFromCamera();

  Future<ReceiptImagePick> pickFromGallery();
}

class ReceiptImagePick {
  const ReceiptImagePick.path(String this.imagePath) : error = null;

  /// [error] is a `ScanResult` failure code: `cancelled`, `permission_denied`
  /// or `unavailable`.
  const ReceiptImagePick.failure(String this.error) : imagePath = null;

  final String? imagePath;
  final String? error;

  bool get isSuccess => imagePath != null;
}

class NoopReceiptImageSource implements ReceiptImageSource {
  const NoopReceiptImageSource();

  @override
  Future<ReceiptImagePick> pickFromCamera() async =>
      const ReceiptImagePick.failure('unavailable');

  @override
  Future<ReceiptImagePick> pickFromGallery() async =>
      const ReceiptImagePick.failure('unavailable');
}
