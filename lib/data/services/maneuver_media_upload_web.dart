import 'package:cloud_functions/cloud_functions.dart';
import 'package:universal_html/html.dart' as html;

import 'image_upload_models.dart';

Future<List<String>> uploadManeuverMedia({
  required List<PendingImageUpload> files,
  required String userId,
  required String reportId,
  required String section,
  required String Function(String mimeType) normalizeMimeType,
  required String Function(String mimeType) fileExtensionForMimeType,
}) async {
  final create = FirebaseFunctions.instance.httpsCallable(
    'createManeuverMediaUploadUrls',
  );
  final response = await create.call({
    'reportId': reportId,
    'section': section,
    'files': files
        .map(
          (file) => {
            'contentType': normalizeMimeType(file.mimeType),
            'sizeInBytes': file.sizeInBytes,
          },
        )
        .toList(growable: false),
  });
  final uploads = _readUploads(response.data, files.length);
  final uploadedPaths = <String>[];

  try {
    for (var index = 0; index < files.length; index++) {
      final upload = uploads[index];
      final request = await html.HttpRequest.request(
        upload.uploadUrl,
        method: 'PUT',
        sendData: files[index].bytes,
        requestHeaders: {'Content-Type': upload.contentType},
      );
      final status = request.status ?? 0;
      if (status < 200 || status >= 300) {
        throw StateError('Maneuver media upload failed with HTTP $status.');
      }
      uploadedPaths.add(upload.path);
    }

    final finalize = FirebaseFunctions.instance.httpsCallable(
      'finalizeManeuverMedia',
    );
    await finalize.call({'paths': uploadedPaths});
    return uploadedPaths;
  } catch (_) {
    await deleteManeuverMedia(uploadedPaths);
    rethrow;
  }
}

Future<void> deleteManeuverMedia(Iterable<String> paths) async {
  final values = paths.where((path) => path.trim().isNotEmpty).toList();
  if (values.isEmpty) return;
  final callable = FirebaseFunctions.instance.httpsCallable(
    'deleteManeuverMedia',
  );
  await callable.call({'paths': values});
}

List<_UploadInstruction> _readUploads(Object? data, int expectedCount) {
  final map = data is Map ? Map<String, dynamic>.from(data) : null;
  final rawUploads = map?['uploads'];
  if (rawUploads is! List || rawUploads.length != expectedCount) {
    throw StateError('Invalid maneuver media upload response.');
  }
  return rawUploads.map((raw) {
    final item = raw is Map ? Map<String, dynamic>.from(raw) : null;
    if (item == null ||
        item['path'] is! String ||
        item['contentType'] is! String ||
        item['uploadUrl'] is! String) {
      throw StateError('Invalid maneuver media upload instruction.');
    }
    return _UploadInstruction(
      path: item['path'] as String,
      contentType: item['contentType'] as String,
      uploadUrl: item['uploadUrl'] as String,
    );
  }).toList(growable: false);
}

class _UploadInstruction {
  const _UploadInstruction({
    required this.path,
    required this.contentType,
    required this.uploadUrl,
  });

  final String path;
  final String contentType;
  final String uploadUrl;
}
