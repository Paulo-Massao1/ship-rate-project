import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static Future<List<String>> uploadImages(
    List<XFile> images,
    String locationId,
    String recordId,
  ) async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < images.length; i++) {
      try {
        final bytes = await images[i].readAsBytes();
        final ref = storage.ref('registros/$locationId/$recordId/${timestamp}_$i.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
      }
    }

    return urls;
  }

  static Future<void> deleteImages(List<String> urls) async {
    final storage = FirebaseStorage.instance;

    for (final url in urls) {
      try {
        await storage.refFromURL(url).delete();
      } catch (e) {
        debugPrint('Error deleting image: $e');
      }
    }
  }
}
