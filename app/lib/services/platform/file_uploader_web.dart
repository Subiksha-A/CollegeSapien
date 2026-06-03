import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PlatformFileUploader {
  static Future<void> uploadFile({
    required Reference ref,
    required PlatformFile file,
    required SettableMetadata metadata,
    required void Function(double)? onProgress,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw ArgumentError('File bytes are null on web');
    }
    final uploadTask = ref.putData(bytes, metadata);

    uploadTask.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress?.call(event.bytesTransferred / event.totalBytes);
      }
    });

    await uploadTask;
  }
}
