// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildEmbeddedDocumentWidget({
  required List<int> bytes,
  required String mimeType,
  String? url,
  required Widget fallbackWidget,
}) {
  return _EmbeddedWebDocumentViewer(
    bytes: bytes,
    mimeType: mimeType,
    url: url,
  );
}

class _EmbeddedWebDocumentViewer extends StatefulWidget {
  final List<int> bytes;
  final String mimeType;
  final String? url;

  const _EmbeddedWebDocumentViewer({
    required this.bytes,
    required this.mimeType,
    this.url,
  });

  @override
  State<_EmbeddedWebDocumentViewer> createState() => _EmbeddedWebDocumentViewerState();
}

class _EmbeddedWebDocumentViewerState extends State<_EmbeddedWebDocumentViewer> {
  late String _viewId;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    _viewId = 'web_doc_iframe_${DateTime.now().microsecondsSinceEpoch}';

    String iframeSrc;
    if (widget.url != null && widget.url!.startsWith('http')) {
      iframeSrc = 'https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(widget.url!)}';
    } else {
      final blob = html.Blob([widget.bytes], widget.mimeType);
      _objectUrl = html.Url.createObjectUrlFromBlob(blob);
      iframeSrc = _objectUrl!;
    }

    // Register iframe view factory
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = iframeSrc
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  void dispose() {
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
