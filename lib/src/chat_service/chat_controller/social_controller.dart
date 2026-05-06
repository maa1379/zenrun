import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:zenrun/src/social_pages/utils/platform_video_controller.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../core/network/DataState.dart';
import '../../../core/widgets/Costance.dart';
import '../../api_models_repo/api_service.dart';
import '../../api_models_repo/models/post_model.dart';
import '../flush_helper.dart';
import '../widgets/post_comment_widget.dart';
import 'api_helper.dart';
import 'comment_controller.dart';

class SocialController extends GetxController {
  var feedPosts = <PostModel>[].obs;
  var reelsPosts = <PostModel>[].obs;
  int activeTab = 0;
  var isLoading = true.obs;

  PageController reelsPageController = PageController();
  final TextEditingController coinToPostAmount = TextEditingController();

  var currentReelIndex = 0.obs;
  var currentFeedIndex = 0.obs;
  var currentHorizontalIndices = <int, int>{}.obs;

  var pageScale = 1.0.obs;
  var pageBorderRadius = 0.0.obs;

  var likeCounts = <int, RxInt>{}.obs;
  var commentCounts = <int, RxInt>{}.obs;
  var isLikedMap = <int, RxBool>{}.obs;
  var userLikeIds = <int, int?>{}.obs;
  var isProcessingLike = <int, bool>{}.obs;

  var isMuted = false.obs;

  // Keys are "feed_0_0" or "reel_0_0" to avoid collisions between tabs.
  var videoControllers = <String, PlatformVideoController>{}.obs;

  // Insertion-ordered key list for LRU eviction.
  final List<String> _controllerKeys = [];

  // Max simultaneous controllers to keep in memory.
  static const int _maxControllers = 6;

  Future<void> shareLink(PostModel post) async {
    final String link = "https://gerehapp.ir/post/${post.id}";
    final String text = "${post.description ?? ''}\n\nمشاهده در گره:\n$link";
    await Share.share(text, subject: "اشتراک پست از گره");
  }

  Future<void> shareFile(PostModel post) async {
    if (kIsWeb) {
      await shareLink(post);
      return;
    }
    final mediaList = getMediaList(post);
    if (mediaList.isEmpty) return;
    final String url = mediaList.first;
    ApiHelper.showLoading();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final isVid = isVideo(url);
        final mimeType = isVid ? 'video/mp4' : 'image/jpeg';
        final ext = isVid ? 'mp4' : 'jpg';
        // XFile.fromData works on all platforms without dart:io.
        final xFile = XFile.fromData(
          bytes,
          name: 'share_${post.id}.$ext',
          mimeType: mimeType,
        );
        ApiHelper.dismissLoading();
        await Share.shareXFiles([xFile], text: post.description ?? "");
      } else {
        ApiHelper.dismissLoading();
        FlushHelper.error("Error downloading the file");
      }
    } catch (e) {
      ApiHelper.dismissLoading();
      FlushHelper.error("There was a problem");
    }
  }

  @override
  void onClose() {
    cleanup();
    super.onClose();
  }

  Future<void> _initializeControllerAtIndex(
    int index,
    int hIndex,
    bool isReel,
  ) async {
    final list = isReel ? reelsPosts : feedPosts;
    if (index >= list.length || index < 0) return;

    String? url = _getMediaUrl(list[index], hIndex);
    if (url == null || !isVideo(url)) return;

    String prefix = isReel ? "reel" : "feed";
    String key = "${prefix}_${index}_$hIndex";

    if (videoControllers.containsKey(key)) return;

    // Evict the oldest controller if over limit.
    _evictIfNeeded();

    try {
      final controller = PlatformVideoController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.controller.setLooping(true);
      controller.controller.setVolume(isMuted.value ? 0.0 : 1.0);

      videoControllers[key] = controller;
      _controllerKeys.add(key);
      videoControllers.refresh();

      // Play if this item is currently visible.
      if ((isReel && index == currentReelIndex.value && activeTab == 1) ||
          (!isReel && index == currentFeedIndex.value && activeTab == 0)) {
        controller.controller.play();
      }
    } catch (e) {
      debugPrint("Video Error: $e");
    }
  }

  void _evictIfNeeded() {
    while (_controllerKeys.length >= _maxControllers) {
      final oldest = _controllerKeys.removeAt(0);
      final ctrl = videoControllers.remove(oldest);
      ctrl?.dispose();
    }
  }

  void onReelPageChanged(int index) {
    currentReelIndex.value = index;
    pauseAllVideos();

    String currentVideoKey = "reel_${index}_0";
    final vCtrl = videoControllers[currentVideoKey];
    if (vCtrl != null && vCtrl.controller.value.isInitialized) {
      vCtrl.controller.play();
    } else {
      _initializeControllerAtIndex(index, 0, true);
    }
    fetchPostDetails(reelsPosts[index].id ?? 0);
    _preloadNext(index, true);
  }

  void onFeedItemVisible(int index) {
    if (currentFeedIndex.value == index) return;
    currentFeedIndex.value = index;

    pauseAllVideos();

    String currentVideoKey = "feed_${index}_0";
    final vCtrl = videoControllers[currentVideoKey];

    if (vCtrl != null && vCtrl.controller.value.isInitialized) {
      vCtrl.controller.play();
    } else {
      _initializeControllerAtIndex(index, 0, false);
    }

    fetchPostDetails(feedPosts[index].id ?? 0);
    _preloadNext(index, false);
  }

  void pauseAllVideos() {
    videoControllers.forEach((key, vCtrl) {
      if (vCtrl.controller.value.isPlaying) {
        vCtrl.controller.pause();
      }
    });
  }

  void _preloadNext(int current, bool isReel) {
    final list = isReel ? reelsPosts : feedPosts;
    if (current + 1 < list.length) {
      _initializeControllerAtIndex(current + 1, 0, isReel);
    }
  }

  Future<void> fetchPostDetails(int postId) async {
    _ensureMapsInitialized(postId);
    final likeRes = await ApiHelper.post(
      "Like.aspx",
      queryParams: {"postId": postId.toString()},
    );
    final commentRes = await ApiHelper.post(
      "Comment.aspx",
      queryParams: {"postId": postId.toString()},
    );

    if (likeRes.isSuccess && commentRes.isSuccess) {
      String? userPhone = await PrefHelpers.getUser();
      final likesList = (likeRes.data as List);

      likeCounts[postId]!.value = likesList.length;
      commentCounts[postId]!.value = (commentRes.data as List).length;

      var myLike = likesList.firstWhereOrNull((e) => e['Email'] == userPhone);
      if (myLike != null) {
        isLikedMap[postId]!.value = true;
        userLikeIds[postId] = myLike['id'];
      } else {
        isLikedMap[postId]!.value = false;
        userLikeIds[postId] = null;
      }
    }
  }

  Future<void> fetchInitialFeed() async {
    cleanup();
    isLoading.value = true;
    final res = await ApiHelper.post(
      "Post.aspx",
      queryParams: {"email": await PrefHelpers.getUser()},
    );

    if (res.isSuccess) {
      List<PostModel> sourceList = (res.data as List)
          .map((e) => PostModel.fromJson(e))
          .toList();

      if (sourceList.length < 10) {
        final data = await _fetchPostsAndReels(
          Get.context!,
          (await PrefHelpers.getUser()) ?? "",
        );
        sourceList.addAll(data);
      }

      feedPosts.assignAll(sourceList.where((e) => e.isReels == false).toList());
      reelsPosts.assignAll(
        sourceList.reversed.where((e) => e.isReels == true).toList(),
      );

      if (feedPosts.isNotEmpty) {
        await _initializeControllerAtIndex(0, 0, false);
        fetchPostDetails(feedPosts[0].id ?? 0);
      }
      if (reelsPosts.isNotEmpty) {
        await _initializeControllerAtIndex(0, 0, true);
      }
    }
    isLoading.value = false;
  }

  Future<List<PostModel>> _fetchPostsAndReels(
    BuildContext context,
    String email,
  ) async {
    final postRes = await ApiService.instance.getPosts(email);
    List<PostModel> fetchedContent = [];
    if (postRes is DataSuccess) fetchedContent.addAll(postRes.data ?? []);
    if (fetchedContent.length < 10) {
      final randomRes = await ApiService.instance.getRandomPost();
      if (randomRes is DataSuccess) {
        for (var p in randomRes.data ?? []) {
          if (!fetchedContent.any((fp) => fp.id == p.id)) fetchedContent.add(p);
        }
      }
    }
    return fetchedContent;
  }

  Future<void> toggleLike(int postId) async {
    if (isProcessingLike[postId] == true) return;

    _ensureMapsInitialized(postId);
    isProcessingLike[postId] = true;

    bool isCurrentlyLiked = isLikedMap[postId]!.value;
    int? likeId = userLikeIds[postId];

    isLikedMap[postId]!.value = !isCurrentlyLiked;
    likeCounts[postId]!.value += isLikedMap[postId]!.value ? 1 : -1;

    try {
      if (isCurrentlyLiked) {
        if (likeId != null) {
          final res = await ApiHelper.post(
            "DeleteLike.aspx",
            queryParams: {"id": likeId.toString()},
          );
          if (!res.isSuccess) {
            _revertLikeState(postId, isCurrentlyLiked);
          } else {
            userLikeIds[postId] = null;
          }
        }
      } else {
        final res = await ApiHelper.post(
          "SetLike.aspx",
          queryParams: {
            "Email": await PrefHelpers.getUser(),
            "postId": postId.toString(),
            "commentId": "0",
          },
        );

        if (res.isSuccess) {
          await _syncLikeIdOnly(postId);
        } else {
          _revertLikeState(postId, isCurrentlyLiked);
        }
      }
    } catch (e) {
      _revertLikeState(postId, isCurrentlyLiked);
    } finally {
      isProcessingLike[postId] = false;
    }
  }

  Future<void> _syncLikeIdOnly(int postId) async {
    final likeRes = await ApiHelper.post(
      "Like.aspx",
      queryParams: {"postId": postId.toString()},
    );
    if (likeRes.isSuccess) {
      String? userPhone = await PrefHelpers.getUser();
      final likesList = (likeRes.data as List);
      var myLike = likesList.firstWhereOrNull((e) => e['Email'] == userPhone);
      if (myLike != null) {
        userLikeIds[postId] = myLike['id'];
      }
    }
  }

  void _revertLikeState(int postId, bool previousState) {
    isLikedMap[postId]!.value = previousState;
    likeCounts[postId]!.value += previousState ? 1 : -1;
  }

  void _ensureMapsInitialized(int postId) {
    if (!likeCounts.containsKey(postId)) likeCounts[postId] = 0.obs;
    if (!commentCounts.containsKey(postId)) commentCounts[postId] = 0.obs;
    if (!isLikedMap.containsKey(postId)) isLikedMap[postId] = false.obs;
    if (!userLikeIds.containsKey(postId)) userLikeIds[postId] = null;
    if (!isProcessingLike.containsKey(postId)) isProcessingLike[postId] = false;
  }

  void onVerticalPageChanged(int index) {}

  void onHorizontalPageChanged(int vIndex, int hIndex) {
    pauseAllVideos();

    String currentVideoKey = "${vIndex}_$hIndex";
    final vCtrl = videoControllers[currentVideoKey];

    if (vCtrl != null && vCtrl.controller.value.isInitialized) {
      vCtrl.controller.play();
    }
  }

  void cleanup() {
    for (var c in videoControllers.values) {
      c.dispose();
    }
    videoControllers.clear();
    _controllerKeys.clear();
    currentReelIndex.value = 0;
    currentFeedIndex.value = 0;
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    videoControllers.forEach(
      (k, v) => v.controller.setVolume(isMuted.value ? 0.0 : 1.0),
    );
  }

  void showCommentModal(int postId) {
    pageScale.value = 0.88;
    pageBorderRadius.value = 30.0;
    final commentCtrl = Get.put(CommentController());
    commentCtrl.getCommentList(postId: postId.toString());
    Get.bottomSheet(
      PostCommentWidget(postId: postId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    ).whenComplete(() {
      pageScale.value = 1.0;
      pageBorderRadius.value = 0.0;
    });
  }

  void changeCommentCount(int postId, int delta) {
    if (commentCounts.containsKey(postId)) {
      commentCounts[postId]!.value += delta;
    } else {
      commentCounts[postId] = RxInt(delta > 0 ? delta : 0);
    }
  }

  List<String> getMediaList(PostModel post) {
    List<String> media = [];
    if (post.video?.isNotEmpty == true) media.add(post.video!);
    if (post.image1?.isNotEmpty == true) media.add(post.image1!);
    if (post.image2?.isNotEmpty == true) media.add(post.image2!);
    if (post.image3?.isNotEmpty == true) media.add(post.image3!);
    if (post.image4?.isNotEmpty == true) media.add(post.image4!);
    if (post.image5?.isNotEmpty == true) media.add(post.image5!);
    return media;
  }

  bool isVideo(String url) =>
      url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');

  String? _getMediaUrl(PostModel post, int index) {
    final list = getMediaList(post);
    return index < list.length ? list[index] : null;
  }

  Future<void> setCoinToPost(String postId) async {
    if (coinToPostAmount.text.isEmpty) return;

    ViewHelper.showLoading();
    final res = await ApiService.instance.setCoinToPost(
      postId,
      coinToPostAmount.text,
    );
    ViewHelper.dismissLoading();

    if (res is DataSuccess) {
      final post = [
        ...reelsPosts,
        ...feedPosts,
      ].firstWhereOrNull((p) => p.id.toString() == postId);
      if (post != null) {
        post.Amount = (post.Amount ?? 0) + int.parse(coinToPostAmount.text);
      }
      coinToPostAmount.clear();
      if (Get.context!.mounted) {
        ViewHelper.showSuccessDialog(Get.context!, "Sent successfully");
      }
    } else {
      if (Get.context!.mounted) {
        ViewHelper.showErrorDialog(
          Get.context!,
          text: "You don't have enough coins",
        );
      }
    }
  }
}
