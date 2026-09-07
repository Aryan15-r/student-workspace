import 'embedded_viewer_stub.dart'
  if (dart.library.html) 'embedded_viewer_web.dart';
import 'package:flutter/material.dart';

class EmbeddedDocumentViewer extends StatelessWidget {
  final List<int> bytes;
  final String mimeType;
  final String? url;
  final Widget fallbackWidget;

  const EmbeddedDocumentViewer({
    super.key,
    required this.bytes,
    required this.mimeType,
    this.url,
    required this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return buildEmbeddedDocumentWidget(
      bytes: bytes,
      mimeType: mimeType,
      url: url,
      fallbackWidget: fallbackWidget,
    );
  }
}
