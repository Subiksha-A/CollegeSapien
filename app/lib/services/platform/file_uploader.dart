export 'file_uploader_stub.dart'
    if (dart.library.io) 'file_uploader_mobile.dart'
    if (dart.library.js_interop) 'file_uploader_web.dart';
