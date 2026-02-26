Future<void> downloadImplementation({
  required List<int> bytes,
  required String fileName,
  String? mimeType,
}) async {
  // No-op for non-web platforms (unless implemented via path_provider/open_file)
  print('Download not implemented on this platform');
}
