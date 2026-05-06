import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Stubs used on Flutter Web. These branches are never reached at runtime
// because create_story.dart guards them all with !kIsWeb.
VideoPlayerController createFileVideoController(String path) {
  throw UnsupportedError('File-based video playback is not supported on web');
}

Widget buildFileImage(String path) {
  throw UnsupportedError('File-based images are not supported on web');
}
