import 'dart:io';
import 'dart:ui';

import 'package:badges/badges.dart' as badge;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:zenrun/src/shop_pages/providers/basket_provider.dart';

import '../../../generated/assets.dart';
import '../../api_models_repo/models/product_model.dart';
import '../../social_pages/widgets/audio_player.dart';
import 'package:http/http.dart' as http;
import 'package:toln/toln.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart'; // ایمپورت اضافه شده

class DetailProductPage extends StatefulWidget {
  const DetailProductPage({super.key, required this.data, this.isPaid});

  final ProductModel data;
  final bool? isPaid;

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  YoutubePlayerController? youtubePlayerController;

  bool get isDiscount => widget.data.priceTakhfif != widget.data.price;

  bool _isAccessGranted(BuildContext context) {
    if (widget.isPaid == true) return true;
    return context.read<ProfileProvider>().profile?.hasActiveSubscription ?? false;
  }

  @override
  void initState() {
    super.initState();
    _initYoutube();
    _initVideoPlayer();
  }

  void _initYoutube() {
    if (widget.data.youtubeFileUrl != null && widget.data.youtubeFileUrl!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.data.youtubeFileUrl!);
      if (videoId != null) {
        youtubePlayerController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    if (widget.data.fileUrlEn?.endsWith(".mp4") == true) {
      try {
        videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.data.fileUrlEn!),
        );
        await videoPlayerController?.initialize();

        if (!mounted) return; // چک کردن mounted قبل از setState

        chewieController = ChewieController(
          videoPlayerController: videoPlayerController!,
          autoPlay: false,
          looping: false,
          aspectRatio: videoPlayerController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: TextStyle(color: Colors.white)));
          },
        );
        setState(() {});
      } catch (e) {
        debugPrint("Video initialization error: $e");
      }
    }
  }

  Future<void> openFileFromUrl(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("Error opening file: $e");
      if(mounted) ViewHelper.showErrorDialog(context, text: "Error opening file");
    }
  }

  @override
  void deactivate() {
    youtubePlayerController?.pause();
    videoPlayerController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    youtubePlayerController?.dispose();
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelper.appBar(
        widget.data.title ?? "",
        action: Consumer<BasketProvider>(
          builder: (context, provider, child) {
            return UiHelper.iconBox(
              badge.Badge(
                badgeStyle: const badge.BadgeStyle(badgeColor: ColorsHelper.btn2),
                badgeContent: Text(
                  provider.badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                showBadge: true,
                child: const Icon(Icons.shopping_cart_outlined, size: 28),
              ),
                  () async {
                await provider.getAndPushFromDb(context, isPush: true);
              },
              color: Colors.transparent,
            );
          },
        ),
      ),
      bottomNavigationBar: _buildNavBtn(),
      body: Container(
        height: 100.h,
        width: 100.w,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.imagesImg4),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: [
            const Gap(0),
            if (widget.data.images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(height: 22.h, autoPlay: true),
                items: widget.data.images
                    .where((element) => element.isNotEmpty)
                    .map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: UiHelper.borderRadius16,
                          image: DecorationImage(
                            image: FastCachedImageProvider(i), // استفاده از کش ایمیج
                            onError: (exception, stackTrace) {},
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            const Gap(10),
            Divider(color: ColorsHelper.btn2, indent: 2.5.w, endIndent: 2.5.w),
            const Gap(10),
            Container(
              width: 100.w,
              margin: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: UiHelper.borderRadius16,
                color: ColorsHelper.white,
                boxShadow: UiHelper.shadow1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.description ?? "",
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  const Gap(10),
                  if (widget.data.fileUrlEn?.endsWith(".mp4") == true) _buildVideoBox(),
                  if (widget.data.fileUrlEn?.endsWith(".mp3") == true) _buildAudioBox(),
                  _buildYoutubeBox(),
                  _buildFileBox(),
                ],
              ),
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubeBox() {
    if (youtubePlayerController == null) return const SizedBox();

    return Builder(
      builder: (context) {
        final granted = _isAccessGranted(context);
        return SizedBox(
          height: 25.h,
          width: 100.w,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: UiHelper.borderRadius16,
                child: YoutubePlayer(
                  controller: youtubePlayerController!,
                  width: 100.w,
                  showVideoProgressIndicator: true,
                  bottomActions: [
                    CurrentPosition(),
                    ProgressBar(isExpanded: true),
                    FullScreenButton(
                      controller: youtubePlayerController,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
              if (!granted)
                ClipRRect(
                  borderRadius: UiHelper.borderRadius16,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        height: 25.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: UiHelper.borderRadius16,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_open, color: Colors.red, size: 50),
                              Text("Not purchased".toLn(),
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileBox() {
    if (widget.data.fileUrlEn == null || widget.data.fileUrlEn == "null") {
      return const SizedBox();
    }
    return Builder(
      builder: (context) {
        final granted = _isAccessGranted(context);
        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Center(
            child: UiHelper.buttonMain2(
              !granted
                  ? () {}
                  : () async {
                      if (!kIsWeb) {
                        ViewHelper.showLoading();
                        await openFileFromUrl(
                          widget.data.fileUrlEn ?? "",
                          widget.data.fileUrlEn.toString().split("/").last,
                        );
                        ViewHelper.dismissLoading();
                      } else {
                        ViewHelper.showErrorDialog(context,
                            text: "Web platform not supported");
                      }
                    },
              !granted ? "Show file (Not purchased)" : "Show file",
              width: 95.w,
              height: 5.h,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoBox() {
    if (chewieController == null || videoPlayerController?.value.isInitialized != true) {
      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    }

    return SizedBox(
      height: 25.h,
      width: 100.w,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.5.w),
        decoration: BoxDecoration(
          border: Border.all(color: ColorsHelper.btn2, width: 1.5),
          borderRadius: UiHelper.borderRadius16,
        ),
        child: ClipRRect(
          borderRadius: UiHelper.borderRadius16,
          child: Chewie(controller: chewieController!),
        ),
      ),
    );
  }

  Widget _buildAudioBox() {
    return SizedBox(
      width: 100.w,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: ColorsHelper.btn2, width: 1.5),
          borderRadius: UiHelper.borderRadius16,
        ),
        child: AudioPlayerWidget(
          audioUrl: widget.data.fileUrlEn ?? "",
          imageUrl: widget.data.image1 ?? "",
        ),
      ),
    );
  }

  Widget _buildNavBtn() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final hasSubscription =
            profileProvider.profile?.hasActiveSubscription ?? false;
        return Container(
          height: 15.h,
          width: 100.w,
          margin: EdgeInsets.only(bottom: 5.h, left: 2.5.w, right: 2.5.w),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: UiHelper.borderRadius16,
            color: ColorsHelper.white,
            boxShadow: UiHelper.shadow1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasSubscription)
                        Text(
                          "Free".toLn(),
                          style: TextStyle(
                            color: ColorsHelper.btn1,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else ...[
                        Text(
                          "\$${widget.data.price}".toLn(),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            decoration: !isDiscount ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        if (isDiscount)
                          Text(
                            "\$${widget.data.priceTakhfif}".toLn(),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
              Text(
                hasSubscription
                    ? "You have an active subscription — enjoy free access!".toLn()
                    : "You can make the purchase if you have other coins.".toLn(),
                style: TextStyle(
                  color: hasSubscription ? ColorsHelper.btn1 : Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}