import 'image_upload_models.dart';

Future<List<String>> uploadManeuverMedia({
  required List<PendingImageUpload> files,
  required String userId,
  required String reportId,
  required String section,
  required String Function(String mimeType) normalizeMimeType,
  required String Function(String mimeType) fileExtensionForMimeType,
}) {
  throw UnsupportedError('Maneuver media upload is unavailable.');
}

Future<void> deleteManeuverMedia(Iterable<String> paths) {
  throw UnsupportedError('Maneuver media deletion is unavailable.');
}
