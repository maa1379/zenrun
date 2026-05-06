import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenrun/core/widgets/image_picker_helper.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/circle_model.dart';
import 'package:zenrun/src/api_models_repo/models/follow_model.dart';
import 'package:zenrun/src/api_models_repo/models/post_model.dart';
import 'package:zenrun/src/api_models_repo/models/profile_model.dart';
import 'package:zenrun/src/chat_service/chat_controller/social_controller.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';
import 'package:zenrun/src/profile_pages/providers/comment_provider.dart';
import 'package:zenrun/src/profile_pages/providers/like_provider.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../core/network/DataState.dart';
import '../../../core/network/api_helper.dart';
import '../../../core/widgets/Costance.dart';
import '../../api_models_repo/api_service.dart';
import '../../api_models_repo/models/tag_model.dart';

enum ProfileViewState { loading, loaded, error }

enum FollowStatus { following, notFollowing, requested }

class ProfilePageData {
  final ProfileModel userProfile;
  final List<PostModel> posts;
  final List<FollowModel> followers; // کسانی که یوزر را فالو کرده‌اند
  final List<FollowModel> following; // کسانی که یوزر فالو کرده است
  final List<CircleModel> circles;
  FollowStatus followStatus; // این فیلد دیگر فاینال نیست تا بتوانیم آنی آپدیت کنیم

  ProfilePageData({
    required this.userProfile,
    this.posts = const [],
    this.followers = const [],
    this.following = const [],
    this.circles = const [],
    this.followStatus = FollowStatus.notFollowing,
  });
}

class ProfileProvider extends ChangeNotifier {

  String _myEmail = "";
  final TextEditingController coinToPostAmount = TextEditingController();
  String get myEmail => _myEmail;

  void update()=>notifyListeners();

  List<PostModel> _unifiedPosts = [];
  List<PostModel> get unifiedPosts => _unifiedPosts;

  ProfileViewState _viewState = ProfileViewState.loading;
  ProfileViewState get viewState => _viewState;

  void _setViewState(ProfileViewState state) {
    _viewState = state;
    notifyListeners();
  }

  // --- حفظ متغیرهای قدیمی شما ---
  ProfileModel? profile;
  bool loading = false;
  List<CircleModel> circleList = [];
  List<TagParams> tagParamsList = [];
  List<FollowModel> followingList = [];
  bool isReels = false;
  TextEditingController description = TextEditingController();
  TextEditingController label = TextEditingController();
  bool fileChange1 = false;
  bool fileChange2 = false;
  bool fileChange3 = false;
  bool fileChange4 = false;
  bool fileChange5 = false;
  bool fileChange6 = false;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedCircleTitle;
  String? selectedCircleId;
  String? tooltipText;
  Uint8List? postThumbnailBytes;
  SelectedMedia? profileImage;
  String? profileImageName;
  var filePath1;
  var filePath2;
  var filePath3;
  var filePath4;
  var filePath5;
  var filePath6;
  List<SelectedMedia?> videoFile = List.generate(1, (_) => null);
  List<SelectedMedia?> imageFiles = List.generate(5, (_) => null);
  String? validator;
  Timer? _debounce;
  // -----------------------------

  final int _dailyPostGoal = 5;

  double get dailyPostProgressPercentage {
    if (_unifiedPosts.isEmpty) return 0.0;
    final postsToday = _unifiedPosts.where((post) {
      return post.date?.isSameDay(DateTime.now()) ?? false;
    }).length;
    if (_dailyPostGoal == 0) return 100.0;
    final progress = (postsToday / _dailyPostGoal) * 100;
    return progress.clamp(0.0, 100.0);
  }

  Map<DateTime, int> get last7DaysPosts {
    final Map<DateTime, int> dailyCounts = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayOnly = DateTime(date.year, date.month, date.day);
      dailyCounts[dayOnly] = 0;
    }
    for (final post in _unifiedPosts) {
      if (post.date != null) {
        final postDayOnly = DateTime(post.date!.year, post.date!.month, post.date!.day);
        if (dailyCounts.containsKey(postDayOnly)) {
          dailyCounts[postDayOnly] = dailyCounts[postDayOnly]! + 1;
        }
      }
    }
    return dailyCounts;
  }

  Future<FollowStatus> determineFollowStatus(List<FollowModel> targetFollowers) async {
    _myEmail = await PrefHelpers.getUser() ?? "";

    // در لیست کسانی که این پروفایل را فالو کرده‌اند (Followers)، آیا ایمیل من هست؟
    // در لیست Followers، فیلد email نشان دهنده فالو کننده است.
    final myFollowRecord = targetFollowers.firstWhereOrNull(
          (f) => f.email == _myEmail,
    );

    if (myFollowRecord != null) {
      return (myFollowRecord.isAccept == true)
          ? FollowStatus.following
          : FollowStatus.requested;
    }
    return FollowStatus.notFollowing;
  }


  // --- متد اصلاح شده و بهینه شده ---
  Future<ProfilePageData> fetchProfileData(BuildContext context, String? email) async {
    try {
      final targetEmail = email ?? await PrefHelpers.getUser();
      if (targetEmail == null) throw Exception("User email not found.");
      _myEmail = await PrefHelpers.getUser() ?? "";

      // دریافت پروفایل خودمان در پس‌زمینه (برای پر کردن متغیرهای قدیمی)
      getProfile();

      // درخواست‌های موازی با پارامترهای صحیح طبق توضیح شما
      final results = await Future.wait([
        ApiService.instance.getProfile(email: targetEmail), // [0]
        ApiService.instance.getOtherUserPosts(targetEmail), // [1]
        // لیست کسانی که این یوزر فالو کرده (Following) -> پارامتر email
        ApiService.instance.getFollowList(email: targetEmail), // [2]
        // لیست کسانی که این یوزر را فالو کرده‌اند (Followers) -> پارامتر followEmail
        ApiService.instance.getFollowList2(followEmail: targetEmail), // [3]
        ApiService.instance.getUserCircleList(email: targetEmail), // [4]
      ]);

      final profileRes = results[0] as DataState<ProfileModel>;
      final postRes = results[1] as DataState<List<PostModel>>;
      final followingRes = results[2] as DataState<List<FollowModel>>;
      final followersRes = results[3] as DataState<List<FollowModel>>;
      final circlesRes = results[4] as DataState<List<CircleModel>>;

      if (profileRes is! DataSuccess) throw Exception("Failed to load profile.");

      final profileData = profileRes.data!;
      final posts = (postRes is DataSuccess) ? postRes.data ?? [] : <PostModel>[];
      final following = (followingRes is DataSuccess) ? followingRes.data ?? [] : <FollowModel>[];
      final followers = (followersRes is DataSuccess) ? followersRes.data ?? [] : <FollowModel>[];
      final circles = (circlesRes is DataSuccess) ? circlesRes.data ?? [] : <CircleModel>[];

      _unifiedPosts = posts;

      // --- بخش مهم: پر کردن پروفایل‌ها به صورت موازی ---

      // 1. برای لیست Following: ما دنبال پروفایل کسی هستیم که فالو شده (followEmail)
      final followingFutures = following.map((item) async {
        if (item.followEmail != null && item.followEmail!.isNotEmpty) {
          final res = await ApiService.instance.getProfile(email: item.followEmail!);
          item.profileModel = res.data;
        }
      });

      // 2. برای لیست Followers: ما دنبال پروفایل کسی هستیم که فالو کرده (email)
      final followersFutures = followers.map((item) async {
        if (item.email != null && item.email!.isNotEmpty) {
          final res = await ApiService.instance.getProfile(email: item.email!);
          item.profileModel = res.data;
        }
      });

      // انجام تمام درخواست‌های پروفایل باهم (Parallel Execution)
      await Future.wait([...followingFutures, ...followersFutures]);

      // --- پایان بخش اصلاح شده ---

      // لاجیک تشخیص اینکه آیا من (کاربر لاگین شده) این پروفایل را فالو دارم؟
      // باید در لیست Followers این پروفایل، دنبال ایمیل خودم بگردم
      final followStatus = await determineFollowStatus(followers);

      _setViewState(ProfileViewState.loaded);

      return ProfilePageData(
        userProfile: profileData,
        posts: posts,
        followers: followers,
        following: following,
        circles: circles,
        followStatus: followStatus,
      );
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      _setViewState(ProfileViewState.error);
      rethrow;
    }
  }

  Future<void> fetchPostsDetails(List<PostModel> posts, BuildContext context) async {
    if (!context.mounted || posts.isEmpty) return;
    final postDetailFutures = posts.map((post) async {
      await context.read<CommentProvider>().getCommentList(
          context,
          post.id.toString(),
      );
      post.commentList
        ..clear()
        ..addAll(context.read<CommentProvider>().commentList.reversed);
      final likes = await context.read<LikeProvider>().getLikeList(
        post.id.toString(),
      );
      post.likeList
        ..clear()
        ..addAll(likes.reversed);
      post.likeCount = likes.length;
    }).toList();
    await Future.wait(postDetailFutures);
    notifyListeners();
  }

  void _combineCircleAndFollowData(
      List<CircleModel> circles,
      List<FollowModel> following,
      List<TagModel> tags,
      ) {
    for (var follow in following) {
      final circle = circles.firstWhereOrNull((c) => c.id == follow.circleId);
      circle?.followList.add(follow);
      follow.tags.addAll(
        tags.where((tag) => tag.friendEmail == follow.followEmail),
      );
    }
  }

  Future<bool> toggleFollow(
      ProfilePageData pageData, // دیتای فعلی صفحه را میگیریم تا آپدیت کنیم
      String targetEmail,
      String circleId,
      ) async {

    final currentStatus = pageData.followStatus;

    // 1. تغییر وضعیت ظاهری (آنی)
    FollowStatus newStatus;
    if (currentStatus == FollowStatus.notFollowing) {
      newStatus = FollowStatus.requested; // یا فالوینگ (بسته به پرایوت بودن)
    } else {
      newStatus = FollowStatus.notFollowing;
    }

    // آپدیت لوکال برای تغییر سریع دکمه
    pageData.followStatus = newStatus;
    notifyListeners();

    try {
      dynamic res;
      if (currentStatus == FollowStatus.notFollowing) {
        // انجام عملیات فالو
        res = await ApiService.instance.setFollow(
          followEmail: targetEmail,
          circleId: circleId,
        );
      } else {
        // انجام عملیات آنفالو
        // باید آی‌دی رکورد فالو را پیدا کنیم
        final myEmail = await PrefHelpers.getUser();
        // در لیست فالوورهای طرف، رکورد خودم را پیدا میکنم
        final followRecord = pageData.followers.firstWhereOrNull(
              (f) => f.email == myEmail,
        );

        if (followRecord != null) {
          res = await ApiService.instance.deleteFollow(
            id: followRecord.id.toString(),
          );
        } else {
          // اگر رکورد پیدا نشد یعنی دیتای لوکال با سرور سینک نیست
          // پس دوباره دیتا را میگیریم
          return false;
        }
      }

      if (res is DataSuccess) {
        return true;
      } else {
        // اگر شکست خورد، وضعیت را برگردان
        pageData.followStatus = currentStatus;
        notifyListeners();
        return false;
      }
    } catch (e) {
      pageData.followStatus = currentStatus;
      notifyListeners();
      return false;
    }
  }

  // --- تمام متدهای قبلی شما بدون تغییر (فقط clean شده‌اند) ---

  void onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      if (value.isEmpty || value.length <= 6) {
        validator = "Username must be at least 6 characters long";
      } else {
        bool isOk = await ApiService.instance.checkUsername(
          username: value.toLowerCase(),
        );
        if (!isOk) {
          validator = "The username entered is already registered";
        } else {
          validator = null;
        }
      }
      notifyListeners();
    });
  }

  void clean() {
    fileChange1 = false;
    fileChange2 = false;
    fileChange3 = false;
    fileChange4 = false;
    fileChange5 = false;
    fileChange6 = false;
    isReels = false;
    filePath1 = null;
    validator = null;
    filePath2 = null;
    filePath3 = null;
    filePath4 = null;
    filePath5 = null;
    filePath6 = null;
    startDate = null;
    endDate = null;
    postThumbnailBytes = null;
    selectedCircleTitle = null;
    tooltipText = null;
    description.clear();
    label.clear();
  }

  Future<void> getProfile() async {
    final res = await ApiService.instance.getProfile();
    final c = await ApiService.instance.getUserCircleList(
      email: await PrefHelpers.getUser(),
    );
    if (res is DataSuccess) {
      circleList.clear();
      circleList.addAll(c.data ?? []);
      profile = res.data;
      loading = true;
      clean();
      notifyListeners();
    }
  }

  double calculateSProgress({
    required int userPostCount,
    int maxPostLimit = 20,
  }) {
    if (maxPostLimit == 0) return 0;
    return (userPostCount / maxPostLimit) * 100;
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> setFcmProfile() async {
    await _firebaseMessaging.requestPermission();
    // String? token = await _firebaseMessaging.getToken();
    String token = "";
    await getProfile();
    PrefHelpers.setFcm(token ?? "");
    final res = await ApiService.instance.setProfile(
      Bio: profile?.bioC.text,
      Coin: profile?.coin.toString(),
      RCoin: profile?.rCoin.toString(),
      SCoin: profile?.sCoin.toString(),
      ZCoin: profile?.zCoin.toString(),
      city: profile?.cityC.text,
      country: profile?.countryC.text,
      email: profile?.emailC.text,
      family: profile?.familyC.text,
      followerCount: profile?.followerCount.toString(),
      followingCount: profile?.followingCount.toString(),
      image: profile?.imageC.text,
      isActive: profile?.isActive.toString(),
      isMaster: profile?.isMaster.toString(),
      isPrivate: profile?.isPrivate.toString(),
      language: profile?.languageC.text,
      lvl: profile?.lvl.toString(),
      mantaghe: profile?.stateC.text,
      name: profile?.nameC.text,
      phone: profile?.phoneC.text,
      postCount: profile?.postCount.toString(),
      type: profile?.type,
      username: profile?.usernameC.text,
      wallet: profile?.wallet.toString(),
      fcm: token,
      expireEshterak: profile?.expireEshterak?.toIso8601String(),
    );
    if (res is DataSuccess) {
      loading = false;
      update();
      getProfile();
    }
  }

  Future<void> setProfile(BuildContext context) async {
    ViewHelper.showLoading();
    String? photo;
    if (profileImage != null) {
      photo = await ApiHelper.uploaderWeb(
        profileImage!.bytes,
        profileImage!.type,
      );
    }
    final res = await ApiService.instance.setProfile(
      Bio: profile?.bioC.text,
      Coin: profile?.coin.toString(),
      RCoin: profile?.rCoin.toString(),
      SCoin: profile?.sCoin.toString(),
      ZCoin: profile?.zCoin.toString(),
      city: profile?.cityC.text,
      country: profile?.countryC.text,
      email: profile?.emailC.text,
      family: profile?.familyC.text,
      followerCount: profile?.followerCount.toString(),
      followingCount: profile?.followingCount.toString(),
      image: photo ?? profile?.imageC.text,
      isActive: profile?.isActive.toString(),
      isMaster: profile?.isMaster.toString(),
      isPrivate: profile?.isPrivate.toString(),
      language: profile?.languageC.text,
      lvl: profile?.lvl.toString(),
      mantaghe: profile?.stateC.text,
      name: profile?.nameC.text,
      phone: profile?.phoneC.text,
      postCount: profile?.postCount.toString(),
      type: profile?.type,
      username: profile?.usernameC.text,
      wallet: profile?.wallet.toString(),
      fcm: profile?.FCMToken,
      expireEshterak: profile?.expireEshterak?.toIso8601String(),
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      loading = false;
      update();
      getProfile();
      context.pop();
      ViewHelper.showSuccessDialog(context, "Edited successfully.");
    } else {
      ViewHelper.showErrorDialog(context, text: "Please try again");
    }
  }

  Future<bool> payByWallet(BuildContext context, int price) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.setProfile(
      Bio: profile?.bioC.text,
      Coin: profile?.coin.toString(),
      RCoin: profile?.rCoin.toString(),
      SCoin: profile?.sCoin.toString(),
      ZCoin: profile?.zCoin.toString(),
      city: profile?.cityC.text,
      country: profile?.countryC.text,
      email: profile?.emailC.text,
      family: profile?.familyC.text,
      followerCount: profile?.followerCount.toString(),
      followingCount: profile?.followingCount.toString(),
      image: profile?.imageC.text,
      isActive: profile?.isActive.toString(),
      isMaster: profile?.isMaster.toString(),
      isPrivate: profile?.isPrivate.toString(),
      language: profile?.languageC.text,
      lvl: profile?.lvl.toString(),
      mantaghe: profile?.stateC.text,
      name: profile?.nameC.text,
      phone: profile?.phoneC.text,
      postCount: profile?.postCount.toString(),
      type: profile?.type,
      username: profile?.usernameC.text,
      wallet: (profile!.wallet! - price).toString(),
      fcm: profile?.FCMToken,
      expireEshterak: profile?.expireEshterak?.toIso8601String(),
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      loading = false;
      update();
      getProfile();
      return true;
    } else {
      ViewHelper.showErrorDialog(context, text: "Please try again");
      return false;
    }
  }

  Future<bool> payByCoin(BuildContext context, int price, String type) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.setProfile(
      Bio: profile?.bioC.text,
      Coin: type == "C"
          ? (profile!.coin! - price).toString()
          : profile?.coin.toString(),
      RCoin: type == "R"
          ? (profile!.rCoin! - price).toString()
          : profile?.rCoin.toString(),
      SCoin: type == "S"
          ? (profile!.sCoin! - price).toString()
          : profile?.sCoin.toString(),
      ZCoin: type == "Z"
          ? (profile!.zCoin! - price).toString()
          : profile?.zCoin.toString(),
      city: profile?.cityC.text,
      country: profile?.countryC.text,
      email: profile?.emailC.text,
      family: profile?.familyC.text,
      followerCount: profile?.followerCount.toString(),
      followingCount: profile?.followingCount.toString(),
      image: profile?.imageC.text,
      isActive: profile?.isActive.toString(),
      isMaster: profile?.isMaster.toString(),
      isPrivate: profile?.isPrivate.toString(),
      language: profile?.languageC.text,
      lvl: profile?.lvl.toString(),
      mantaghe: profile?.stateC.text,
      name: profile?.nameC.text,
      phone: profile?.phoneC.text,
      postCount: profile?.postCount.toString(),
      type: profile?.type,
      username: profile?.usernameC.text,
      wallet: profile?.wallet.toString(),
      fcm: profile?.FCMToken,
      expireEshterak: profile?.expireEshterak?.toIso8601String(),
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      loading = false;
      update();
      getProfile();
      return true;
    } else {
      ViewHelper.showErrorDialog(context, text: "Please try again");
      return false;
    }
  }

  Map<String, int> countFollowersByCircle() {
    final Map<String, int> counts = {};
    for (final circle in circleList) {
      final name = circle.title ?? 'Unknown';
      counts[name] = circle.followList.length;
    }
    return counts;
  }

  Map<String, List<String>> activityByDate() {
    final Map<String, List<String>> data = {};
    for (final circle in circleList) {
      if (selectedCircleTitle != null && circle.title != selectedCircleTitle) {
        continue;
      }
      for (final f in circle.followList) {
        for (final tag in f.tags) {
          if (tag.date == null) continue;
          if (startDate != null &&
              !(tag.date!.isAfter(startDate!.subtract(Duration(days: 1))) &&
                  tag.date!.isBefore(endDate!.add(Duration(days: 1))))) {
            continue;
          }
          final dateStr = DateFormat('dd MMM').format(tag.date!);
          data.putIfAbsent(dateStr, () => []).add(f.profileModel?.email ?? "");
        }
      }
    }
    return data;
  }

  Map<FollowModel, int> activityByFollowerFiltered() {
    final Map<FollowModel, int> activity = {};
    for (final circle in circleList) {
      if (selectedCircleTitle != null && circle.title != selectedCircleTitle) {
        continue;
      }

      for (final f in circle.followList) {
        final filteredTags = f.tags.where((tag) {
          if (startDate != null &&
              (tag.date == null || tag.date!.isBefore(startDate!))) {
            return false;
          }
          if (endDate != null &&
              (tag.date == null || tag.date!.isAfter(endDate!))) {
            return false;
          }
          return true;
        }).toList();

        activity[f] = filteredTags.length;
      }
    }
    return activity;
  }

  Future<void> setPost(
      BuildContext context, {
        required bool isTask,
        required bool isEditMode,
        int? postId,
        required List<String?> existingImageUrls,
        String? existingVideoUrl,
      }) async {
    ViewHelper.showLoading();

    try {
      final List<String?> finalImageLinks = List.generate(5, (_) => null);
      String? finalVideoLink;

      for (int i = 0; i < 5; i++) {
        if (imageFiles[i] != null) {
          final newLink = await ApiHelper.uploaderWeb(
            imageFiles[i]!.bytes,
            imageFiles[i]!.type,
          );
          finalImageLinks[i] = newLink;
        } else if (existingImageUrls.length > i &&
            existingImageUrls[i] != null) {
          finalImageLinks[i] = existingImageUrls[i];
        }
      }

      if (videoFile.firstOrNull != null) {
        final newLink = await ApiHelper.uploaderWeb(
          videoFile.first!.bytes,
          videoFile.first!.type,
        );
        finalVideoLink = newLink;
      } else if (existingVideoUrl != null) {
        finalVideoLink = existingVideoUrl;
      }
      final res = await ApiService.instance.setPostOrReels(
        id: postId?.toString(),
        image1: finalImageLinks.elementAtOrNull(0) ?? "",
        image2: finalImageLinks.elementAtOrNull(1) ?? "",
        image3: finalImageLinks.elementAtOrNull(2) ?? "",
        image4: finalImageLinks.elementAtOrNull(3) ?? "",
        image5: finalImageLinks.elementAtOrNull(4) ?? "",
        video: finalVideoLink ?? "",
        description: description.text,
        label: isTask ? "Task" : isReels?"Reels":"Post",
        userImage: profile?.image ?? "",
        isAccept: "false",
        isLikeToCoin: "false",
        isReels: isReels.toString(),
      );

      ViewHelper.dismissLoading();
      if (res is DataSuccess) {
        clean();
        // await fetchProfileData(context, profile?.email);
        // context.read<SocialProvider>().fetchData(context);
        Get.find<SocialController>().fetchInitialFeed();
      } else if (res is DataFailed) {
        ViewHelper.showErrorDialog(context);
      }
    } catch (e) {
      ViewHelper.dismissLoading();
      // ViewHelper.showErrorDialog(context, text: "An error occurred");
    }
  }

  Future<void> setTags(BuildContext context, bool isTask) async {
    Future.wait(
      tagParamsList.map((tag) async {
        await ApiService.instance.setTag(
          friendEmail: tag.friendEmail,
          description: tag.description,
          isTask: isTask,
          circleId: tag.circleId,
          taskId: tag.taskId,
        );
      }),
    );
  }

  Future<void> setCoinToPost(BuildContext context, String postId,) async {
    if (coinToPostAmount.text.isEmpty) return;

    ViewHelper.showLoading();
    final res = await ApiService.instance.setCoinToPost(
      postId,
      coinToPostAmount.text,
    );
    ViewHelper.dismissLoading();

    if (res is DataSuccess) {
      final post = [..._unifiedPosts]
          .firstWhereOrNull((p) => p.id.toString() == postId);
      if (post != null) {
        post.Amount = (post.Amount ?? 0) + int.parse(coinToPostAmount.text);
      }
      coinToPostAmount.clear();
      notifyListeners();
      if (context.mounted) {
        ViewHelper.showSuccessDialog(context, "Sent successfully");
      }
    } else {
      if (context.mounted) {
        ViewHelper.showErrorDialog(
          context,
          text: "You don't have enough coins",
        );
      }
    }
  }

}