import 'package:video_player/video_player.dart';

// Stub for cached_video_player_plus on Flutter Web.
// The real package uses dart:io which is unavailable on web.
// PlatformVideoController never instantiates this on web — it is here
// only to satisfy the Dart compiler's conditional import.
class CachedVideoPlayerPlus {
  CachedVideoPlayerPlus.networkUrl(Uri uri,
      {Map<String, String> httpHeaders = const {}});

  VideoPlayerController get controller => throw UnimplementedError();
  Future<void> initialize() => throw UnimplementedError();
  void dispose() {}
}
