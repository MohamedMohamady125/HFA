import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = {};

Widget buildWebVideoEmbed(String embedUrl) {
  final viewType = 'yt-embed-${embedUrl.hashCode}';
  if (_registeredViews.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = embedUrl
        ..allowFullscreen = true;
      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });
  }
  return HtmlElementView(viewType: viewType);
}
