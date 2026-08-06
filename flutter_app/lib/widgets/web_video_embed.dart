// Inline video embed that works on Flutter web via an iframe.
// On mobile this resolves to the stub (never used there — mobile uses webview_flutter).
export 'web_video_embed_stub.dart' if (dart.library.html) 'web_video_embed_web.dart';
