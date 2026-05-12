import 'dart:typed_data';

class PendingImageUpload {
  const PendingImageUpload({
    required this.bytes,
    required this.mimeType,
    required this.originalName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String originalName;

  int get sizeInBytes => bytes.lengthInBytes;
}

class ImageUploadException implements Exception {
  const ImageUploadException(
    this.message, {
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}
