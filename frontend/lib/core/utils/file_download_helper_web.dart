import 'dart:html' as html;

Future<void> downloadImplementation({
  required List<int> bytes,
  required String fileName,
  String? mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType ?? 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
