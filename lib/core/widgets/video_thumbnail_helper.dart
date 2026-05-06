import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;


class VideoThumbnailWidget extends StatefulWidget {
  final dynamic videoUrl;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late Future<dynamic> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    if(widget.videoUrl.toString().startsWith("http")){
    _thumbnailFuture = VideoThumbnailCacheManager.getCachedThumbnail(
      widget.videoUrl,
    );
    }else{
      _thumbnailFuture = VideoThumbnailCacheManager.getCachedThumbnailFromFile(
        widget.videoUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              SizedBox(
                width: 50,
                height: 50,
                child: const Center(child: CircularProgressIndicator()),
              );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return widget.errorWidget ??
              SizedBox(
                width: 50,
                height: 50,
                child: const Center(child: Icon(Icons.broken_image)),
              );
        }
        return snapshot.data is String ?Image.file(io.File(snapshot.data!), fit: BoxFit.cover):Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}

class VideoThumbnailCacheManager {
  static const key = 'videoThumbnailCache';

  static final CacheManager _cacheManager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // مدت زمان اعتبار کش
      maxNrOfCacheObjects: 100,
    ),
  );

  /// هش کردن url برای کلید کش
  static String _hashUrl(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  /// گرفتن thumbnail با کش
  static Future<Uint8List?> getCachedThumbnail(
    String url, {
    int maxHeight = 200,
  }) async {
    final fileKey = _hashUrl(url);

    // تلاش برای خواندن از کش
    final fileInfo = await _cacheManager.getFileFromCache(fileKey);
    if (fileInfo != null && await fileInfo.file.exists()) {
      final bytes = await fileInfo.file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    }

    // اگر نبود، thumbnail تولید می‌کنیم
    final data = await VideoThumbnail.thumbnailData(
      video: url,
      imageFormat: ImageFormat.JPEG,
      maxHeight: maxHeight,
      quality: 75,
    );

    // کش کردن فایل
    await _cacheManager.putFile(fileKey, data);

    return data;
  }

  static Future<String> getCachedThumbnailFromFile(
    Uint8List url, {
    int maxHeight = 200,
  }) async {

    final data = await VideoThumbnail.thumbnailFile(
      video: await getFilePathFromBytes(url,DateTime.now().toIso8601String()),
      imageFormat: ImageFormat.JPEG,
      maxHeight: maxHeight,
      quality: 60,
    );
    print(data.path);
    return data.path;
  }

  /// پاک کردن کش (اختیاری)
  static Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}


Future<String> getFilePathFromBytes(Uint8List data, String filename, {String mimeType = 'application/octet-stream'}) async {
  final dir = await getTemporaryDirectory();
  final file = io.File('${dir.path}/$filename.mp4');
  await file.writeAsBytes(data);
  return file.path;
}
