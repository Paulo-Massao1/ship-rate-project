import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'image_upload_models.dart';

Future<List<String>> uploadImages({
  required List<PendingImageUpload> images,
  required String locationId,
  required String recordId,
  required int timestamp,
  required String Function(String mimeType) normalizeMimeType,
  required String Function(String mimeType) fileExtensionForMimeType,
}) async {
  final callable = FirebaseFunctions.instance.httpsCallable(
    'createNavSafetyImageUploadUrls',
  );

  final response = await callable
      .call(<String, dynamic>{
        'locationId': locationId,
        'recordId': recordId,
        'files': images
            .map(
              (image) => <String, dynamic>{
                'contentType': normalizeMimeType(image.mimeType),
                'sizeInBytes': image.sizeInBytes,
              },
            )
            .toList(),
      })
      .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const ImageUploadException(
          'A preparacao do upload expirou. Tente novamente.',
          code: 'deadline-exceeded',
        ),
      );

  final uploads = _extractUploads(response.data, expectedCount: images.length);
  final uploadedPaths = <String>[];

  for (var i = 0; i < images.length; i++) {
    final image = images[i];
    final instruction = uploads[i];

    debugPrint(
      'ImageUploadService.uploadImages[$i] starting upload '
      'size=${image.sizeInBytes} mimeType=${instruction.contentType} '
      'path=${instruction.path} [signed-url]',
    );

    try {
      await _putFile(
        url: instruction.uploadUrl,
        bytes: image.bytes,
        headers: instruction.uploadHeaders,
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw const ImageUploadException(
          'O envio da imagem expirou. Tente novamente com uma conexao estavel.',
          code: 'upload-timeout',
        ),
      );

      uploadedPaths.add(instruction.path);
      debugPrint(
        'ImageUploadService.uploadImages[$i] upload completed '
        'path=${instruction.path} [signed-url]',
      );
    } on FirebaseFunctionsException catch (e, stackTrace) {
      debugPrint(
        'ImageUploadService.uploadImages[$i] FirebaseFunctionsException '
        '[signed-url]: code=${e.code} message=${e.message}',
      );
      debugPrint('$stackTrace');
      await deleteImages(uploadedPaths);
      throw _mapFunctionsException(e, image: image);
    } on ImageUploadException {
      await deleteImages(uploadedPaths);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint(
        'ImageUploadService.uploadImages[$i] unexpected error [signed-url]: $e',
      );
      debugPrint('$stackTrace');
      await deleteImages(uploadedPaths);
      throw ImageUploadException(
        'Falha inesperada ao enviar a imagem "${image.originalName}".',
        cause: e,
      );
    }
  }

  try {
    final finalizeCallable = FirebaseFunctions.instance.httpsCallable(
      'finalizeNavSafetyImages',
    );
    final finalizeResponse = await finalizeCallable
        .call(<String, dynamic>{
          'paths': uploadedPaths,
        })
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const ImageUploadException(
            'A finalizacao do upload expirou. Tente novamente.',
            code: 'deadline-exceeded',
          ),
        );

    return _extractFinalizedDownloadUrls(
      finalizeResponse.data,
      expectedCount: uploadedPaths.length,
    );
  } on FirebaseFunctionsException catch (e, stackTrace) {
    debugPrint(
      'ImageUploadService.uploadImages finalize FirebaseFunctionsException '
      '[signed-url]: code=${e.code} message=${e.message}',
    );
    debugPrint('$stackTrace');
    await deleteImages(uploadedPaths);
    throw _mapFunctionsException(
      e,
      image: images.first,
    );
  } on ImageUploadException {
    await deleteImages(uploadedPaths);
    rethrow;
  } catch (e, stackTrace) {
    debugPrint(
      'ImageUploadService.uploadImages finalize unexpected error [signed-url]: $e',
    );
    debugPrint('$stackTrace');
    await deleteImages(uploadedPaths);
    throw ImageUploadException(
      'Falha inesperada ao finalizar o upload das imagens.',
      cause: e,
    );
  }
}

Future<void> deleteImages(Iterable<String> pathsOrUrls) async {
  final values = pathsOrUrls.where((value) => value.trim().isNotEmpty).toSet();
  if (values.isEmpty) return;

  try {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'deleteNavSafetyImages',
    );

    await callable.call(<String, dynamic>{
      'pathsOrUrls': values.toList(),
    });
    debugPrint(
      'ImageUploadService.deleteImages deleted ${values.length} image(s) '
      '[signed-url]',
    );
  } catch (e, stackTrace) {
    debugPrint('ImageUploadService.deleteImages failed [signed-url]: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _putFile({
  required String url,
  required List<int> bytes,
  required Map<String, String> headers,
}) async {
  final request = await html.HttpRequest.request(
    url,
    method: 'PUT',
    sendData: bytes,
    requestHeaders: headers,
  );

  final status = request.status ?? 0;
  if (status >= 200 && status < 300) {
    return;
  }

  throw ImageUploadException(
    'Falha no upload HTTP da imagem. Status: $status.',
    code: 'upload-http-$status',
    cause: request.responseText,
  );
}

List<_SignedUploadInstruction> _extractUploads(
  dynamic data, {
  required int expectedCount,
}) {
  final map = data is Map ? Map<String, dynamic>.from(data) : null;
  final rawUploads = map?['uploads'];

  if (rawUploads is! List || rawUploads.length != expectedCount) {
    throw const ImageUploadException(
      'Resposta invalida ao preparar o upload das imagens.',
      code: 'invalid-upload-instructions',
    );
  }

  return rawUploads
      .map((entry) {
        final item = entry is Map ? Map<String, dynamic>.from(entry) : null;
        final headers = item?['uploadHeaders'] is Map
            ? Map<String, String>.from(item!['uploadHeaders'])
            : null;

        if (
            item == null ||
            headers == null ||
            item['path'] is! String ||
            item['contentType'] is! String ||
            item['uploadUrl'] is! String) {
          throw const ImageUploadException(
            'Resposta invalida ao preparar o upload das imagens.',
            code: 'invalid-upload-instructions',
          );
        }

        return _SignedUploadInstruction(
          path: item['path'] as String,
          contentType: item['contentType'] as String,
          uploadUrl: item['uploadUrl'] as String,
          uploadHeaders: headers,
        );
      })
      .toList(growable: false);
}

List<String> _extractFinalizedDownloadUrls(
  dynamic data, {
  required int expectedCount,
}) {
  final map = data is Map ? Map<String, dynamic>.from(data) : null;
  final rawUploads = map?['uploads'];

  if (rawUploads is! List || rawUploads.length != expectedCount) {
    throw const ImageUploadException(
      'Resposta invalida ao finalizar o upload das imagens.',
      code: 'invalid-finalized-uploads',
    );
  }

  return rawUploads.map((entry) {
    final item = entry is Map ? Map<String, dynamic>.from(entry) : null;
    if (item == null || item['downloadUrl'] is! String) {
      throw const ImageUploadException(
        'Resposta invalida ao finalizar o upload das imagens.',
        code: 'invalid-finalized-uploads',
      );
    }

    return item['downloadUrl'] as String;
  }).toList(growable: false);
}

ImageUploadException _mapFunctionsException(
  FirebaseFunctionsException exception, {
  required PendingImageUpload image,
}) {
  switch (exception.code) {
    case 'unauthenticated':
      return ImageUploadException(
        'Voce precisa estar autenticado para enviar imagens.',
        code: exception.code,
        cause: exception,
      );
    case 'permission-denied':
      return ImageUploadException(
        'Voce nao tem permissao para enviar imagens para este registro.',
        code: exception.code,
        cause: exception,
      );
    case 'invalid-argument':
      return ImageUploadException(
        exception.message ??
            'Os dados da imagem enviada sao invalidos para o upload.',
        code: exception.code,
        cause: exception,
      );
    case 'deadline-exceeded':
      return ImageUploadException(
        'A preparacao do upload expirou. Tente novamente.',
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

class _SignedUploadInstruction {
  const _SignedUploadInstruction({
    required this.path,
    required this.contentType,
    required this.uploadUrl,
    required this.uploadHeaders,
  });

  final String path;
  final String contentType;
  final String uploadUrl;
  final Map<String, String> uploadHeaders;
}
