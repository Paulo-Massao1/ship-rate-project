import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import 'image_upload_models.dart';
import 'image_upload_web_backend_stub.dart'
    if (dart.library.html) 'image_upload_web_backend.dart'
    if (dart.library.io) 'image_upload_mobile.dart'
    as image_upload_backend;

export 'image_upload_models.dart';

class ImageUploadService {
  static const int maxImagesPerRecord = 3;
  static const int maxImageSizeBytes = 20 * 1024 * 1024;
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  // Content types resolvable from a file extension. Anything outside this
  // list is uploaded as application/octet-stream.
  static const Map<String, String> _contentTypeByExtension = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'json': 'application/json',
    'xml': 'application/xml',
    'gpx': 'application/gpx+xml',
    'kml': 'application/vnd.google-earth.kml+xml',
    'kmz': 'application/vnd.google-earth.kmz',
    'zip': 'application/zip',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };
  static const List<String> supportedMimeTypes = <String>[
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const String htmlAcceptAttribute =
      'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp';
  static const String supportedFormatsLabel = 'JPG, PNG, WEBP';

  static String normalizeMimeType(String mimeType) {
    switch (mimeType.trim().toLowerCase()) {
      case 'image/jpg':
      case 'image/jpeg':
      case 'image/pjpeg':
        return 'image/jpeg';
      case 'image/x-png':
      case 'image/png':
        return 'image/png';
      case 'image/webp':
        return 'image/webp';
      default:
        return mimeType.trim().toLowerCase();
    }
  }

  static String mimeTypeFromFileName(String fileName) {
    final lower = fileName.trim().toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String fileExtensionForMimeType(String mimeType) {
    switch (normalizeMimeType(mimeType)) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/jpeg':
      default:
        return 'jpg';
    }
  }

  static String fileExtensionFromFileName(String fileName) {
    final lower = fileName.trim().toLowerCase();
    final dotIndex = lower.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == lower.length - 1) return 'bin';

    final extension = lower.substring(dotIndex + 1);
    final isValid = RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension);
    return isValid ? extension : 'bin';
  }

  static String contentTypeFromFileName(String fileName) {
    return _contentTypeByExtension[fileExtensionFromFileName(fileName)] ??
        'application/octet-stream';
  }

  static bool isImageContentType(String contentType) {
    return contentType.trim().toLowerCase().startsWith('image/');
  }

  static String? validateSelectedFile(PendingImageUpload file) {
    if (file.bytes.isEmpty) {
      return 'fileEmpty';
    }

    if (file.sizeInBytes > maxFileSizeBytes) {
      return 'fileTooLarge';
    }

    return null;
  }

  static String? validateSelectedImage(PendingImageUpload image) {
    final normalizedMimeType = normalizeMimeType(image.mimeType);

    if (image.bytes.isEmpty) {
      return 'imageEmpty';
    }

    if (!supportedMimeTypes.contains(normalizedMimeType)) {
      return 'formatNotSupported';
    }

    if (image.sizeInBytes > maxImageSizeBytes) {
      return 'imageTooLarge';
    }

    return null;
  }

  static Future<PendingImageUpload?> pickImage(ImagePickSource source) {
    return image_upload_backend.pickImage(
      source: source,
      accept: htmlAcceptAttribute,
      mimeTypeFromFileName: mimeTypeFromFileName,
    );
  }

  /// Picks a single file of any type and returns it as a pending upload.
  ///
  /// On web an html input[type=file] is used because file_picker is not
  /// reliable across every browser (notably iOS PWAs). On other platforms
  /// file_picker is used as before.
  static Future<PendingImageUpload?> pickFile() async {
    if (kIsWeb) {
      try {
        return await _pickFileWeb();
      } on ImageUploadException {
        rethrow;
      } catch (e, stackTrace) {
        debugPrint('ImageUploadService.pickFile web fallback failed: $e');
        debugPrint('$stackTrace');
        throw ImageUploadException(
          'Anexo de arquivos disponivel apenas no app.',
          code: 'web-file-pick-failed',
          cause: e,
        );
      }
    }

    final result = await FilePicker.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) return null;

    final fileName = picked.name.trim().isNotEmpty
        ? picked.name.trim()
        : 'arquivo_${DateTime.now().millisecondsSinceEpoch}';

    return PendingImageUpload(
      bytes: bytes,
      mimeType: contentTypeFromFileName(fileName),
      originalName: fileName,
    );
  }

  /// Web implementation of [pickFile] backed by a plain html file input,
  /// mirroring the approach already used by the web image picker backend.
  static Future<PendingImageUpload?> _pickFileWeb() {
    final body = html.document.body;
    if (body == null) {
      throw const ImageUploadException(
        'Anexo de arquivos disponivel apenas no app.',
        code: 'web-file-pick-unavailable',
      );
    }

    final completer = Completer<PendingImageUpload?>();
    final input = html.FileUploadInputElement()..style.display = 'none';

    body.append(input);

    input.onChange.first.then((_) async {
      final file = input.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;

      final result = reader.result;
      final Uint8List bytes;
      if (result is Uint8List) {
        bytes = result;
      } else if (result is ByteBuffer) {
        bytes = result.asUint8List();
      } else {
        completer.completeError(
          const ImageUploadException(
            'Nao foi possivel ler o arquivo selecionado.',
            code: 'web-file-read-failed',
          ),
        );
        return;
      }

      final fileName = file.name.trim().isNotEmpty
          ? file.name.trim()
          : 'arquivo_${DateTime.now().millisecondsSinceEpoch}';

      completer.complete(
        PendingImageUpload(
          bytes: bytes,
          mimeType: contentTypeFromFileName(fileName),
          originalName: fileName,
        ),
      );
    }).catchError((Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    input.click();
    return completer.future.whenComplete(input.remove);
  }

  static Future<List<String>> uploadImages(
    List<PendingImageUpload> images,
    String locationId,
    String recordId,
  ) async {
    if (images.isEmpty) return const <String>[];

    if (images.length > maxImagesPerRecord) {
      throw const ImageUploadException(
        'maxImagesExceeded',
      );
    }

    debugPrint(
      'ImageUploadService.uploadImages start: count=${images.length}, '
      'locationId=$locationId, recordId=$recordId',
    );

    for (final image in images) {
      final validationError = validateSelectedImage(image);
      if (validationError != null) {
        throw ImageUploadException(validationError);
      }
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return image_upload_backend.uploadImages(
      images: images,
      locationId: locationId,
      recordId: recordId,
      timestamp: timestamp,
      normalizeMimeType: normalizeMimeType,
      fileExtensionForMimeType: fileExtensionForMimeType,
    );
  }

  /// Uploads generic (non-image) files to the same storage path used by the
  /// record photos, keeping each file's own content type and extension.
  static Future<List<String>> uploadFiles(
    List<PendingImageUpload> files,
    String locationId,
    String recordId,
  ) async {
    if (files.isEmpty) return const <String>[];

    for (final file in files) {
      final validationError = validateSelectedFile(file);
      if (validationError != null) {
        throw ImageUploadException(validationError);
      }
    }

    debugPrint(
      'ImageUploadService.uploadFiles start: count=${files.length}, '
      'locationId=$locationId, recordId=$recordId',
    );

    final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
    final urls = <String>[];

    try {
      // Files are uploaded one at a time so each keeps the content type and
      // extension derived from its own name (the backend callbacks only
      // receive a mime type).
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final uploaded = await image_upload_backend.uploadImages(
          images: <PendingImageUpload>[file],
          locationId: locationId,
          recordId: recordId,
          timestamp: baseTimestamp + i,
          normalizeMimeType: (_) => contentTypeFromFileName(file.originalName),
          fileExtensionForMimeType: (_) =>
              fileExtensionFromFileName(file.originalName),
        );
        urls.addAll(uploaded);
      }
    } catch (e) {
      await deleteImages(urls);
      rethrow;
    }

    return urls;
  }

  static Future<void> deleteImages(Iterable<String> urls) async {
    final uniqueUrls = urls.where((url) => url.trim().isNotEmpty).toSet();
    if (uniqueUrls.isEmpty) return;

    await image_upload_backend.deleteImages(uniqueUrls);
  }
}
