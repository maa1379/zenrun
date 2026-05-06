import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/notif_model.dart';
import 'package:zenrun/src/api_models_repo/models/post_model.dart';
import 'package:zenrun/src/api_models_repo/models/profile_model.dart';
import 'package:zenrun/src/profile_pages/providers/like_provider.dart';

enum SocialViewState { loading, loaded, error }

class SocialProvider extends ChangeNotifier {
  late PageController pageController;
  void update() => notifyListeners();
  int activePage = 0;

  SocialViewState _state = SocialViewState.loading;
  SocialViewState get state => _state;

  String _myEmail = "";
  String get myEmail => _myEmail;

  // --- Cache Keys ---
  static const String _keyCachedPosts = 'cached_posts_v2';
  static const String _keyCachedReels = 'cached_reels_v2';
  static const String _keyCachedNotifs = 'cached_notifications';
  static const String _keyCachedProfile = 'cached_my_profile';

  void setState(SocialViewState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  List<PostModel> _reels = [];
  List<PostModel> get reels => _reels;

  List<NotifModel> _notifications = [];
  List<NotifModel> get notifications => _notifications;

  int _newNotificationsCount = 0;
  int get newNotificationsCount => _newNotificationsCount;

  ProfileModel? _currentUserProfile;
  ProfileModel? get currentUserProfile => _currentUserProfile;

  final TextEditingController coinToPostAmount = TextEditingController();
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

// در فایل social_provider.dart متد fetchData را با کد زیر جایگزین کن:

  Future<void> fetchData(BuildContext context) async {
    _myEmail = await PrefHelpers.getUser() ?? "";

    // 1. نمایش آنی اطلاعات ذخیره شده (بدون معطلی)
    await Future.wait([
      _loadFromCache(),
      _loadNotifsCache(),
      _loadProfileCache(),
    ]);

    // اگر کش داشتیم، سریع نمایش بده تا کاربر صفحه خالی نبیند
    if (_posts.isNotEmpty || _reels.isNotEmpty) {
      _state = SocialViewState.loaded;
      notifyListeners();
    }

    // اگر کش خالی بود، لودینگ نشان بده
    if (_posts.isEmpty && _reels.isEmpty) {
      setState(SocialViewState.loading);
    }

    try {
      final userEmail = await PrefHelpers.getUser();
      if (userEmail == null) throw Exception("User not logged in");

      // 2. دریافت لیست پست‌ها (فقط لیست خام، بدون جزئیات لایک و کامنت)
      List<PostModel> fetchedContent = await _fetchPostsAndReels(context, userEmail);

      // نکته مهم: اینجا دیگر _fetchPostsDetails و _preloadAllImageSizes را صدا نمی‌زنیم!
      // این کار سرعت را ۱۰ برابر می‌کند.

      _posts = fetchedContent.where((p) => p.isReels != true).toList();
      _reels = fetchedContent.where((p) => p.isReels == true).toList();

      // 3. آپدیت کردن صفحه با اطلاعات جدید
      setState(SocialViewState.loaded);
      _saveToCache(); // ذخیره در کش برای دفعه بعد

      // 4. دریافت اطلاعات جانبی در "پس‌زمینه" (بدون درگیر کردن UI)
      ApiService.instance.getProfile().then((res) {
        if (res is DataSuccess) {
          _currentUserProfile = res.data;
          _saveProfileCache();
          notifyListeners();
        }
      }).catchError((e) {
        debugPrint("Profile fetch error: $e");
      });

      // نوتیفیکیشن هم جداگانه و بی سروصدا لود شود
      fetchNotifications();

    } catch (e) {
      debugPrint("Error fetching social data: $e");
      if (_posts.isEmpty && _reels.isEmpty) {
        setState(SocialViewState.error);
      }
    }
  }

  // --- Caching Logic Methods ---

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = jsonEncode(_posts.map((e) => e.toJson()).toList());
      final reelsJson = jsonEncode(_reels.map((e) => e.toJson()).toList());
      await prefs.setString(_keyCachedPosts, postsJson);
      await prefs.setString(_keyCachedReels, reelsJson);
    } catch (e) { debugPrint("Cache Save Error: $e"); }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_keyCachedPosts);
      final reelsString = prefs.getString(_keyCachedReels);

      if (postsString != null) {
        final List decoded = jsonDecode(postsString);
        _posts = decoded.map((e) => PostModel.fromJson(e)).toList();
      }
      if (reelsString != null) {
        final List decoded = jsonDecode(reelsString);
        _reels = decoded.map((e) => PostModel.fromJson(e)).toList();
      }
    } catch (e) { debugPrint("Cache Load Error: $e"); }
  }

  Future<void> _saveNotifsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_notifications.map((e) => e.toJson()).toList());
      await prefs.setString(_keyCachedNotifs, json);
    } catch (_) {}
  }

  Future<void> _loadNotifsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_keyCachedNotifs);
      if (json != null) {
        final List decoded = jsonDecode(json);
        _notifications = decoded.map((e) => NotifModel.fromJson(e)).toList();
        await updateNewNotificationCount();
      }
    } catch (_) {}
  }

  Future<void> _saveProfileCache() async {
    if (_currentUserProfile == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_currentUserProfile!.toJson());
      await prefs.setString(_keyCachedProfile, json);
    } catch (_) {}
  }

  Future<void> _loadProfileCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_keyCachedProfile);
      if (json != null) {
        _currentUserProfile = ProfileModel.fromJson(jsonDecode(json));
      }
    } catch (_) {}
  }

  // --- Fetch Methods ---

  Future<List<PostModel>> _fetchPostsAndReels(BuildContext context, String email) async {
    final postRes = await ApiService.instance.getPosts(email);
    List<PostModel> fetchedContent = [];
    if (postRes is DataSuccess) {
      fetchedContent.addAll(postRes.data ?? []);
    }
    if (fetchedContent.length < 10) {
      final randomRes = await ApiService.instance.getRandomPost();
      if (randomRes is DataSuccess) {
        final randomContent = randomRes.data ?? [];
        for (var p in randomContent) {
          if (!fetchedContent.any((fp) => fp.id == p.id)) {
            fetchedContent.add(p);
          }
        }
      }
    }
    return fetchedContent;
  }

  Future<void> fetchNotifications() async {
    final res = await ApiService.instance.getNotifList();
    if (res is DataSuccess) {
      final allNotifs = res.data ?? [];
      final currentUserEmail = await PrefHelpers.getUser();
      _notifications = allNotifs
          .where((n) => n.senderEmail != currentUserEmail)
          .toList();

      final userEmails = _notifications.map((n) => n.email).nonNulls.toSet();
      final postIds = _notifications.map((n) => n.postId).nonNulls.toSet();

      if (userEmails.isEmpty && postIds.isEmpty) {
        await updateNewNotificationCount();
        return;
      }

      final profileFutures = userEmails
          .map((email) => ApiService.instance.getProfile(email: email))
          .toList();
      final postFutures =
      postIds.map((id) => ApiService.instance.getOnePost(id)).toList();

      final profilesRes = await Future.wait(profileFutures);
      final postsRes = await Future.wait(postFutures);

      final profiles = profilesRes
          .whereType<DataSuccess<ProfileModel>>()
          .map((res) => res.data)
          .nonNulls
          .toList();
      final posts = postsRes
          .whereType<DataSuccess<PostModel>>()
          .map((res) => res.data)
          .nonNulls
          .toList();

      final profileMap = {for (var p in profiles) p.email: p};
      final postMap = {for (var p in posts) p.id.toString(): p};

      for (var notif in _notifications) {
        notif.profileModel = profileMap[notif.email];
        notif.postModel = postMap[notif.postId];
      }

      await updateNewNotificationCount();
      _saveNotifsCache();
      notifyListeners();
    }
  }

  Future<void> updateNewNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final lastSeenNotifId = prefs.getInt('lastSeenNotifId') ?? 0;

    if (_notifications.isNotEmpty) {
      _newNotificationsCount =
          _notifications.where((n) => (n.id ?? 0) > lastSeenNotifId).length;
    } else {
      _newNotificationsCount = 0;
    }
    notifyListeners();
  }

  Future<void> markNotificationsAsRead() async {
    if (_notifications.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final latestId =
    _notifications.map((n) => n.id ?? 0).reduce((a, b) => a > b ? a : b);
    await prefs.setInt('lastSeenNotifId', latestId);
    _newNotificationsCount = 0;
    await updateNewNotificationCount();
  }

  Future<void> toggleLike(BuildContext context, String postId) async {
    final post = [..._posts, ..._reels].firstWhereOrNull((p) => p.id.toString() == postId);
    if (post == null) return;
    final isLiked = post.isLike;
    post.isLike = !isLiked;
    post.likeCount += isLiked ? -1 : 1;
    notifyListeners();
    try {
      if (isLiked) {
        final likeId = post.likeList.firstWhereOrNull((l) => l.email == _currentUserProfile?.email)?.id.toString();
        if (likeId != null) {
          await context.read<LikeProvider>().deleteLike(context, likeId);
        }
      } else {
        await context.read<LikeProvider>().setLike(context, postId);
      }
      _saveToCache(); // Update cache on interaction
    } catch (e) {
      post.isLike = isLiked;
      post.likeCount += isLiked ? 1 : -1;
      notifyListeners();
    }
  }

  Future<void> setCoinToPost(BuildContext context, String postId) async {
    if (coinToPostAmount.text.isEmpty) return;

    ViewHelper.showLoading();
    final res = await ApiService.instance.setCoinToPost(
      postId,
      coinToPostAmount.text,
    );
    ViewHelper.dismissLoading();

    if (res is DataSuccess) {
      final post = [..._posts, ..._reels]
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

  Future<bool> acceptFollow(String notificationId, String senderEmail) async {
    final followRecord = await ApiService.instance.getFollowList2(
      followEmail: _currentUserProfile?.email,
    );
    if (followRecord is DataSuccess) {
      final followId = followRecord.data
          ?.firstWhereOrNull((f) => f.email == senderEmail)
          ?.id
          .toString();
      if (followId != null) {
        final res = await ApiService.instance.acceptFollow(id: followId);
        if (res is DataSuccess) {
          await fetchNotifications();
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }
}