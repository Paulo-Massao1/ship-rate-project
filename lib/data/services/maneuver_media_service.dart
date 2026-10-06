import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/maneuver_report.dart';
import 'image_upload_service.dart';
import 'maneuver_media_upload_stub.dart'
    if (dart.library.html) 'maneuver_media_upload_web.dart'
    if (dart.library.io) 'maneuver_media_upload_mobile.dart'
    as media_backend;

enum ManeuverMediaSection { approach, mooring }

class PendingManeuverMedia {
  const PendingManeuverMedia({required this.file, required this.type});

  final PendingImageUpload file;
  final ManeuverMediaType type;
}

class ManeuverMediaException implements Exception {
  const ManeuverMediaException(this.code, [this.cause]);

  final String code;
  final Object? cause;
}

class ManeuverMediaService {
  const ManeuverMediaService();

  static const maxMediaPerSection = 3;
  static const maxMediaSizeBytes = 20 * 1024 * 1024;
  static const _photoTypes = {'image/jpeg', 'image/png', 'image/webp'};
  static const _videoTypes = {'video/mp4', 'video/quicktime'};

  Future<PendingManeuverMedia?> pickPhoto(ImagePickSource source) async {
    final file = await ImageUploadService.pickImage(source);
    if (file == null) return null;
    return _validated(file, ManeuverMediaType.photo);
  }

  Future<PendingManeuverMedia?> pickVideo() async {
    if (kIsWeb) {
      final file = await ImageUploadService.pickFile(
        accept: 'video/mp4,video/quicktime,.mp4,.mov',
      );
      if (file == null) return null;
      return _validated(file, ManeuverMediaType.video);
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final selected = result.files.first;
    final bytes = selected.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ManeuverMediaException('empty');
    }
    final name = selected.name.trim().isEmpty
        ? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4'
        : selected.name.trim();
    final file = PendingImageUpload(
      bytes: bytes,
      mimeType: ImageUploadService.contentTypeFromFileName(name),
      originalName: name,
    );
    return _validated(file, ManeuverMediaType.video);
  }

  Future<List<ManeuverMediaAttachment>> uploadSection({
    required List<PendingManeuverMedia> media,
    required String userId,
    required String reportId,
    required ManeuverMediaSection section,
  }) async {
    if (media.isEmpty) return const [];
    if (media.length > maxMediaPerSection) {
      throw const ManeuverMediaException('limit');
    }
    final validated = media
        .map((item) => _validated(item.file, item.type))
        .toList(growable: false);

    try {
      final paths = await media_backend.uploadManeuverMedia(
        files: validated.map((item) => item.file).toList(growable: false),
        userId: userId,
        reportId: reportId,
        section: section.name,
        normalizeMimeType: ImageUploadService.normalizeMimeType,
        fileExtensionForMimeType: _fileExtensionForMediaType,
      );
      if (paths.length != validated.length) {
        throw const ManeuverMediaException('invalidUploadResponse');
      }

      return List.generate(paths.length, (index) {
        final item = validated[index];
        final normalizedType =
            ImageUploadService.normalizeMimeType(item.file.mimeType);
        return ManeuverMediaAttachment(
          path: paths[index],
          originalName: _safeOriginalName(item.file.originalName),
          contentType: normalizedType,
          sizeBytes: item.file.sizeInBytes,
          type: item.type,
        );
      }, growable: false);
    } on ManeuverMediaException {
      rethrow;
    } catch (error) {
      throw ManeuverMediaException('uploadFailed', error);
    }
  }

  Future<void> deleteMedia(Iterable<String> paths) async {
    final values = paths.where((path) => path.trim().isNotEmpty).toSet();
    if (values.isEmpty) return;
    try {
      await media_backend.deleteManeuverMedia(values);
    } catch (_) {
      // Best-effort cleanup. The report deletion trigger is the final fallback.
    }
  }

  Future<String> getDownloadUrl(String path) {
    return FirebaseStorage.instance.ref(path).getDownloadURL();
  }

  PendingManeuverMedia _validated(
    PendingImageUpload file,
    ManeuverMediaType type,
  ) {
    final contentType = ImageUploadService.normalizeMimeType(file.mimeType);
    final allowed = type == ManeuverMediaType.photo
        ? _photoTypes.contains(contentType)
        : _videoTypes.contains(contentType);
    if (!allowed) throw const ManeuverMediaException('unsupportedType');
    if (file.sizeInBytes <= 0) {
      throw const ManeuverMediaException('empty');
    }
    if (file.sizeInBytes > maxMediaSizeBytes) {
      throw const ManeuverMediaException('tooLarge');
    }
    return PendingManeuverMedia(file: file, type: type);
  }

  String _safeOriginalName(String value) {
    final normalized = value.trim().isEmpty ? 'media' : value.trim();
    return normalized.length <= 160 ? normalized : normalized.substring(0, 160);
  }

  String _fileExtensionForMediaType(String mimeType) {
    return switch (ImageUploadService.normalizeMimeType(mimeType)) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'video/mp4' => 'mp4',
      'video/quicktime' => 'mov',
      _ => 'jpg',
    };
  }
}
