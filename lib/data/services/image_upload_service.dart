import 'package:flutter/foundation.dart';

import 'image_upload_models.dart';
import 'image_upload_web_backend_stub.dart'
    if (dart.library.html) 'image_upload_web_backend.dart'
    if (dart.library.io) 'image_upload_mobile.dart'
    as image_upload_backend;

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

  static Future<PendingImageUpload?> pickImage(ImagePickSource source) {
    return image_upload_backend.pickImage(
      source: source,
      accept: htmlAcceptAttribute,
      mimeTypeFromFileName: mimeTypeFromFileName,
    );
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

    return image_upload_backend.uploadImages(
      images: images,
      locationId: locationId,
      recordId: recordId,
      timestamp: timestamp,
      normalizeMimeType: normalizeMimeType,
      fileExtensionForMimeType: fileExtensionForMimeType,
    );
  }

  static Future<void> deleteImages(Iterable<String> urls) async {
    final uniqueUrls = urls.where((url) => url.trim().isNotEmpty).toSet();
    if (uniqueUrls.isEmpty) return;

    await image_upload_backend.deleteImages(uniqueUrls);
  }
}
