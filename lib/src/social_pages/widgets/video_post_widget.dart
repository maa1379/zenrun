import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:zenrun/src/social_pages/widgets/video_manager.dart';
import '../../../../core/widgets/Costance.dart';
import '../providers/social_provider.dart';

class FlickMultiPlayer extends StatefulWidget {
  const FlickMultiPlayer({
    super.key,
    required this.url,
    this.image,
    required this.flickMultiManager,
  });

  final String url;
  final String? image;
  final FlickMultiManager flickMultiManager;

  @override
  _FlickMultiPlayerState createState() => _FlickMultiPlayerState();
}

class _FlickMultiPlayerState extends State<FlickMultiPlayer> {
  FlickManager? flickManager;
  VideoPlayerController? videoPlayerController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Stream directly from the network URL — no full download before playback.
      // This works on both mobile and web, and starts playing much faster than
      // downloading the whole file first with DefaultCacheManager.getSingleFile().
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      await videoPlayerController!.initialize();
      if (!mounted) {
        videoPlayerController?.dispose();
        videoPlayerController = null;
        return;
      }

      videoPlayerController!.setLooping(true);

      flickManager = FlickManager(
        videoPlayerController: videoPlayerController!,
        autoPlay: false,
      );

      widget.flickMultiManager.init(flickManager!);
      setState(() {});
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  @override
  void dispose() {
    if (flickManager != null) {
      widget.flickMultiManager.remove(flickManager!);
    } else {
      videoPlayerController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (flickManager == null) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: ColorsHelper.btn1),
        ),
      );
    }

    return FlickVideoPlayer(
      flickManager: flickManager!,
      flickVideoWithControls: FlickVideoWithControls(
        videoFit: BoxFit.cover,
        willVideoPlayerControllerChange: false,
        controls: FeedPlayerPortraitControls(
          flickMultiManager: widget.flickMultiManager,
          flickManager: flickManager,
        ),
      ),
      flickVideoWithControlsFullscreen: const FlickVideoWithControls(
        videoFit: BoxFit.contain,
        controls: FlickLandscapeControls(),
        iconThemeData: IconThemeData(size: 40, color: Colors.white),
        textStyle: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}

class FeedPlayer extends StatelessWidget {
  const FeedPlayer({
    super.key,
    required this.url,
    required this.flickMultiManager,
  });

  final FlickMultiManager flickMultiManager;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, provider, child) {
        if (flickMultiManager.isMuted != provider.isMuted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (flickMultiManager.isMuted != provider.isMuted) {
              flickMultiManager.toggleMute();
            }
          });
        }

        return GestureDetector(
          onTap: () {
            provider.toggleMute();
          },
          child: FlickMultiPlayer(
            key: ValueKey(url),
            url: url,
            flickMultiManager: flickMultiManager,
          ),
        );
      },
    );
  }
}
