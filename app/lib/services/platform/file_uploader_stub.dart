import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PlatformFileUploader {
  static Future<void> uploadFile({
    required Reference ref,
    required PlatformFile file,
    required SettableMetadata metadata,
    required void Function(double)? onProgress,
  }) {
    throw UnsupportedError('Platform not supported');
  }
}
