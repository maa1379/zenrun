import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createFileVideoController(String path) {
  return VideoPlayerController.file(File(path));
}

Widget buildFileImage(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.contain,
    width: double.infinity,
    height: double.infinity,
  );
}
