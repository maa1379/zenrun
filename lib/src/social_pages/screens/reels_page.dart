import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:zenrun/src/social_pages/utils/platform_video_controller.dart';

import 'package:zenrun/src/api_models_repo/models/post_model.dart';
import 'package:zenrun/src/social_pages/providers/social_provider.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<SocialProvider>(
        builder: (context, provider, child) {
          if (provider.reels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = provider.reels.reversed.toList();

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            itemBuilder: (context, index) {
              return ReelItem(
                post: list[index],
                index: index,
                pageController: _pageController,
              );
            },
          );
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final PostModel post;
  final int index;
  final PageController pageController;

  const ReelItem({
    Key? key,
    required this.post,
    required this.index,
    required this.pageController,
  }) : super(key: key);

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  PlatformVideoController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_checkPlayState);
    _checkPlayState();
  }

  void _checkPlayState() {
    if (!mounted || !widget.pageController.hasClients) return;

    final currentPage = widget.pageController.page ?? 0.0;
    final distance = (currentPage - widget.index).abs();

    if (distance < 0.2) {
      _initializeAndPlay();
    } else if (distance < 1.5) {
      _initializeAndPause();
    } else {
      _disposeVideo();
    }
  }

  Future<void> _initializeAndPlay() async {
    if (_controller == null) {
      await _initController();
    }
    if (_controller != null && _initialized && !_controller!.controller.value.isPlaying) {
      _controller!.controller.play();
    }
  }

  Future<void> _initializeAndPause() async {
    if (_controller == null) {
      await _initController();
    }
    if (_controller != null && _initialized && _controller!.controller.value.isPlaying) {
      _controller!.controller.pause();
    }
  }

  Future<void> _initController() async {
    final videoUrl = widget.post.video;
    if (videoUrl == null || videoUrl.isEmpty || _controller != null) return;

    try {
      _controller = PlatformVideoController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();

      if (!mounted) {
        _controller!.dispose();
        _controller = null;
        return;
      }

      await _controller!.controller.setLooping(true);

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint("Video Init Error: $e");
    }
  }

  void _disposeVideo() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
      _initialized = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_checkPlayState);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: _initialized && _controller != null
              ? AspectRatio(
                  aspectRatio: _controller!.controller.value.aspectRatio,
                  child: VideoPlayer(_controller!.controller),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
        ),

        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.7, 1.0],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 15,
          right: 15,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  widget.post.description ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.favorite_border, color: Colors.white, size: 30),
                  SizedBox(height: 5),
                  Text("Like", style: TextStyle(color: Colors.white, fontSize: 10)),
                  SizedBox(height: 20),
                  Icon(Icons.comment, color: Colors.white, size: 30),
                  SizedBox(height: 5),
                  Text("Comment", style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
