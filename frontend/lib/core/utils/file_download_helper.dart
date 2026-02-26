import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

abstract class FileDownloadHelper {
  static Future<void> download({
    required List<int> bytes,
    required String fileName,
    String? mimeType,
  }) =>
      downloadImplementation(
          bytes: bytes, fileName: fileName, mimeType: mimeType);
}
