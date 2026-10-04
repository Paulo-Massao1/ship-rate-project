import 'package:firebase_storage/firebase_storage.dart';

import 'image_upload_models.dart';

Future<List<String>> uploadManeuverMedia({
  required List<PendingImageUpload> files,
  required String userId,
  required String reportId,
  required String section,
  required String Function(String mimeType) normalizeMimeType,
  required String Function(String mimeType) fileExtensionForMimeType,
}) async {
  final storage = FirebaseStorage.instance;
  final uploaded = <Reference>[];
  final paths = <String>[];
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  try {
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final contentType = normalizeMimeType(file.mimeType);
      final extension = fileExtensionForMimeType(contentType);
      final path =
          'manobras/$userId/$reportId/$section/${timestamp}_$index.$extension';
      final reference = storage.ref(path);
      await reference.putData(
        file.bytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': userId,
            'reportId': reportId,
            'section': section,
          },
        ),
      );
      uploaded.add(reference);
      paths.add(path);
    }
    return paths;
  } catch (_) {
    await Future.wait(
      uploaded.map(_deleteIgnoringErrors),
    );
    rethrow;
  }
}

Future<void> deleteManeuverMedia(Iterable<String> paths) async {
  final storage = FirebaseStorage.instance;
  await Future.wait(
    paths.map((path) => _deleteIgnoringErrors(storage.ref(path))),
  );
}

Future<void> _deleteIgnoringErrors(Reference reference) async {
  try {
    await reference.delete();
  } catch (_) {
    // Cleanup is best effort; the server-side delete trigger is the fallback.
  }
}
