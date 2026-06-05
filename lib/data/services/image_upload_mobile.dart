import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'image_upload_models.dart';

Future<PendingImageUpload?> pickImage({
  required ImagePickSource source,
  required String accept,
  required String Function(String fileName) mimeTypeFromFileName,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source == ImagePickSource.camera
        ? ImageSource.camera
        : ImageSource.gallery,
  );
  if (picked == null) return null;

  final fileName = picked.name.trim().isNotEmpty
      ? picked.name
      : 'imagem_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final pickedMimeType = picked.mimeType?.trim();

  return PendingImageUpload(
    bytes: await picked.readAsBytes(),
    mimeType: pickedMimeType == null || pickedMimeType.isEmpty
        ? mimeTypeFromFileName(fileName)
        : pickedMimeType,
    originalName: fileName,
  );
}

Future<List<String>> uploadImages({
  required List<PendingImageUpload> images,
  required String locationId,
  required String recordId,
  required int timestamp,
  required String Function(String mimeType) normalizeMimeType,
  required String Function(String mimeType) fileExtensionForMimeType,
}) async {
  final storage = FirebaseStorage.instance;
  final urls = <String>[];
  final uploadedRefs = <Reference>[];

  for (var i = 0; i < images.length; i++) {
    final image = images[i];
    final normalizedMimeType = normalizeMimeType(image.mimeType);
    final extension = fileExtensionForMimeType(normalizedMimeType);
    final ref = storage.ref(
      'registros/$locationId/$recordId/${timestamp}_$i.$extension',
    );
    final metadata = SettableMetadata(contentType: normalizedMimeType);

    debugPrint(
      'ImageUploadService.uploadImages[$i] starting upload '
      'size=${image.sizeInBytes} mimeType=$normalizedMimeType '
      'path=${ref.fullPath}',
    );

    try {
      final uploadTask = ref.putData(image.bytes, metadata);

      await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          uploadTask.cancel();
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-timeout',
            message: 'Image upload timed out',
          );
        },
      );

      uploadedRefs.add(ref);
      debugPrint('ImageUploadService.uploadImages[$i] upload completed');

      final url = await ref.getDownloadURL().timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw FirebaseException(
              plugin: 'firebase_storage',
              code: 'download-url-timeout',
              message: 'Download URL retrieval timed out',
            ),
          );
      urls.add(url);
      debugPrint(
        'ImageUploadService.uploadImages[$i] getDownloadURL completed',
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'ImageUploadService.uploadImages[$i] FirebaseException: '
        'plugin=${e.plugin} code=${e.code} message=${e.message}',
      );
      debugPrint('$stackTrace');

      uploadedRefs.add(ref);
      await _cleanupUploadedRefs(uploadedRefs);

      throw _mapFirebaseException(e, image: image);
    } catch (e, stackTrace) {
      debugPrint('ImageUploadService.uploadImages[$i] unexpected error: $e');
      debugPrint('$stackTrace');

      uploadedRefs.add(ref);
      await _cleanupUploadedRefs(uploadedRefs);

      throw ImageUploadException(
        'Falha inesperada ao enviar a imagem "${image.originalName}".',
        cause: e,
      );
    }
  }

  return urls;
}

Future<void> deleteImages(Iterable<String> urls) async {
  final storage = FirebaseStorage.instance;

  for (final url in urls) {
    try {
      await storage.refFromURL(url).delete();
      debugPrint('ImageUploadService.deleteImages deleted url=$url');
    } catch (e, stackTrace) {
      debugPrint('ImageUploadService.deleteImages failed for $url: $e');
      debugPrint('$stackTrace');
    }
  }
}

Future<void> _cleanupUploadedRefs(Iterable<Reference> refs) async {
  final uniquePaths = <String>{};

  for (final ref in refs) {
    if (!uniquePaths.add(ref.fullPath)) continue;

    try {
      await ref.delete();
      debugPrint('ImageUploadService cleanup deleted ${ref.fullPath}');
    } catch (e, stackTrace) {
      debugPrint('ImageUploadService cleanup failed for ${ref.fullPath}: $e');
      debugPrint('$stackTrace');
    }
  }
}

ImageUploadException _mapFirebaseException(
  FirebaseException exception, {
  required PendingImageUpload image,
}) {
  switch (exception.code) {
    case 'unauthorized':
      return ImageUploadException(
        'Voce nao tem permissao para enviar imagens para este registro.',
        code: exception.code,
        cause: exception,
      );
    case 'canceled':
      return ImageUploadException(
        'O upload da imagem "${image.originalName}" foi cancelado.',
        code: exception.code,
        cause: exception,
      );
    case 'upload-timeout':
    case 'download-url-timeout':
    case 'retry-limit-exceeded':
      return ImageUploadException(
        'O envio da imagem "${image.originalName}" expirou. '
        'Tente novamente com uma conexao estavel.',
        code: exception.code,
        cause: exception,
      );
    case 'object-not-found':
      return ImageUploadException(
        'A imagem enviada nao pode ser localizada no bucket apos o upload.',
        code: exception.code,
        cause: exception,
      );
    default:
      return ImageUploadException(
        'Falha ao enviar a imagem "${image.originalName}".',
        code: exception.code,
        cause: exception,
      );
  }
}
