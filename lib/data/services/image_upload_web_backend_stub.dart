import 'image_upload_models.dart';

Future<List<String>> uploadImages({
  required List<PendingImageUpload> images,
  required String locationId,
  required String recordId,
  required int timestamp,
  required String Function(String mimeType) normalizeMimeType,
  required String Function(String mimeType) fileExtensionForMimeType,
}) {
  throw UnsupportedError('The web image upload backend is only available on web.');
}

Future<void> deleteImages(Iterable<String> urls) {
  throw UnsupportedError('The web image delete backend is only available on web.');
}
