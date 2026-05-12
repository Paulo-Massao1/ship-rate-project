import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'image_upload_models.dart';
import 'image_upload_web_backend_stub.dart'
    if (dart.library.js_interop) 'image_upload_web_backend.dart'
    as image_upload_web_backend;

export 'image_upload_models.dart';

class ImageUploadService {
  static const int maxImagesPerRecord = 3;
  static const int maxImageSizeBytes = 20 * 1024 * 1024;
  static const List<String> supportedMimeTypes = <String>[
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const String htmlAcceptAttribute =
      'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp';
  static const String supportedFormatsLabel = 'JPG, PNG ou WEBP';

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

  static String? validateSelectedImage(PendingImageUpload image) {
    final normalizedMimeType = normalizeMimeType(image.mimeType);

    if (image.bytes.isEmpty) {
      return 'A imagem selecionada esta vazia.';
    }

    if (!supportedMimeTypes.contains(normalizedMimeType)) {
      return 'Formato nao suportado. Use apenas $supportedFormatsLabel.';
    }

    if (image.sizeInBytes > maxImageSizeBytes) {
      return 'Cada imagem deve ter no maximo 20 MB.';
    }

    return null;
  }

  static Future<List<String>> uploadImages(
    List<PendingImageUpload> images,
    String locationId,
    String recordId,
  ) async {
    if (images.isEmpty) return const <String>[];

    if (images.length > maxImagesPerRecord) {
      throw const ImageUploadException(
        'Voce pode anexar no maximo 3 imagens por registro.',
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

    if (kIsWeb) {
      return image_upload_web_backend.uploadImages(
        images: images,
        locationId: locationId,
        recordId: recordId,
        timestamp: timestamp,
        normalizeMimeType: normalizeMimeType,
        fileExtensionForMimeType: fileExtensionForMimeType,
      );
    }

    return _uploadImagesNative(
      images: images,
      locationId: locationId,
      recordId: recordId,
      timestamp: timestamp,
    );
  }

  static Future<List<String>> _uploadImagesNative({
    required List<PendingImageUpload> images,
    required String locationId,
    required String recordId,
    required int timestamp,
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
        debugPrint('ImageUploadService.uploadImages[$i] getDownloadURL completed');
      } on FirebaseException catch (e, stackTrace) {
        debugPrint(
          'ImageUploadService.uploadImages[$i] FirebaseException: '
          'plugin=${e.plugin} code=${e.code} message=${e.message}',
        );
        debugPrint('$stackTrace');

        uploadedRefs.add(ref);
        await _cleanupUploadedRefs(uploadedRefs);

        throw _mapFirebaseException(
          e,
          image: image,
        );
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

  static Future<void> deleteImages(Iterable<String> urls) async {
    final uniqueUrls = urls.where((url) => url.trim().isNotEmpty).toSet();
    if (uniqueUrls.isEmpty) return;

    if (kIsWeb) {
      await image_upload_web_backend.deleteImages(uniqueUrls);
      return;
    }

    final storage = FirebaseStorage.instance;

    for (final url in uniqueUrls) {
      try {
        await storage.refFromURL(url).delete();
        debugPrint('ImageUploadService.deleteImages deleted url=$url');
      } catch (e, stackTrace) {
        debugPrint('ImageUploadService.deleteImages failed for $url: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  static Future<void> _cleanupUploadedRefs(Iterable<Reference> refs) async {
    final uniquePaths = <String>{};

    for (final ref in refs) {
      if (!uniquePaths.add(ref.fullPath)) continue;

      try {
        await ref.delete();
        debugPrint('ImageUploadService cleanup deleted ${ref.fullPath}');
      } catch (e, stackTrace) {
        debugPrint(
          'ImageUploadService cleanup failed for ${ref.fullPath}: $e',
        );
        debugPrint('$stackTrace');
      }
    }
  }

  static ImageUploadException _mapFirebaseException(
    FirebaseException exception, {
    required PendingImageUpload image,
  }) {
    final message = (exception.message ?? '').toLowerCase();

    if (message.contains('cors')) {
      return ImageUploadException(
        'O bucket de imagens bloqueou o upload no navegador. '
        'A configuracao de CORS do Firebase Storage precisa ser aplicada no bucket de producao.',
        code: exception.code,
        cause: exception,
      );
    }

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
}
