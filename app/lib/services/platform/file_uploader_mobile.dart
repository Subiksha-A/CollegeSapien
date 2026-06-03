import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PlatformFileUploader {
  static Future<void> uploadFile({
    required Reference ref,
    required PlatformFile file,
    required SettableMetadata metadata,
    required void Function(double)? onProgress,
  }) async {
    final path = file.path;
    if (path == null) {
      throw ArgumentError('File path is null on mobile');
    }
    final uploadTask = ref.putFile(File(path), metadata);

    uploadTask.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress?.call(event.bytesTransferred / event.totalBytes);
      }
    });

    await uploadTask;
  }
}
