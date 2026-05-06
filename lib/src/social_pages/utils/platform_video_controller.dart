import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

// On web, cached_video_player_plus is not supported (uses native file I/O).
// This wrapper provides a uniform interface: on mobile it uses
// CachedVideoPlayerPlus for disk-caching between sessions; on web it falls
// back to a plain network VideoPlayerController (browser handles caching).
import 'package:cached_video_player_plus/cached_video_player_plus.dart'
    if (dart.library.html) 'package:zenrun/src/social_pages/utils/cached_video_player_stub.dart';

class PlatformVideoController {
  VideoPlayerController? _webController;
  CachedVideoPlayerPlus? _nativeController;

  PlatformVideoController.networkUrl(
    Uri uri, {
    Map<String, String> httpHeaders = const {},
  }) {
    if (kIsWeb) {
      _webController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: httpHeaders,
      );
    } else {
      _nativeController = CachedVideoPlayerPlus.networkUrl(
        uri,
        httpHeaders: httpHeaders,
      );
    }
  }

  VideoPlayerController get controller {
    if (kIsWeb) return _webController!;
    return _nativeController!.controller;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      await _webController!.initialize();
    } else {
      await _nativeController!.initialize();
    }
  }

  void dispose() {
    if (kIsWeb) {
      _webController?.dispose();
    } else {
      _nativeController?.dispose();
    }
  }
}
