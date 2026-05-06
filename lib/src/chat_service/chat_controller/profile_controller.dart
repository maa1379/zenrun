import 'package:get/get.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart'; // اضافه شده برای دریافت حلقه‌ها
import 'package:zenrun/src/api_models_repo/models/circle_model.dart'; // اضافه شده

import '../flush_helper.dart';
import './api_helper.dart';
import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../services/get_profile_service.dart';
import '../../api_models_repo/models/follow_model.dart';
import '../../api_models_repo/models/post_model.dart';
import '../../api_models_repo/models/profile_model.dart';

class ProfileController extends GetxController {
  var profile = ProfileModel().obs;
  var isLoading = true.obs;
  var isMe = false.obs;

  var followStatus = 0.obs;

  RxList<FollowModel> followersList = <FollowModel>[].obs;
  RxList<FollowModel> followingsList = <FollowModel>[].obs;
  var isListLoading = false.obs;

  RxList<PostModel> posts = <PostModel>[].obs;
  var isPostsLoading = false.obs;

  // لیست حلقه‌های کاربر
  RxList<CircleModel> circleList = <CircleModel>[].obs;

  String? currentProfilePhone;

  @override
  void onInit() {
    super.onInit();
    var args = Get.arguments;
    if (args != null && args is ProfileModel) {
      setProfileFromModel(args);
    } else if (args != null && args is String) {
      loadOtherProfile(args);
    } else {
      loadMyProfile();
    }
    _fetchMyCircles(); // گرفتن حلقه‌های خودم موقع لود شدن کنترلر
  }

  @override
  void refresh() {
    onInit();
    super.refresh();
  }

  Future<void> _fetchMyCircles() async {
    String myPhone = await PrefHelpers.getUser() ?? "";
    if (myPhone.isNotEmpty) {
      final res = await ApiService.instance.getUserCircleList(email: myPhone);
      if (res.data != null) {
        circleList.assignAll(res.data!);
      }
    }
  }

  void loadMyProfile() async {
    isLoading.value = true;
    currentProfilePhone = await PrefHelpers.getUser();

    var myData = (await Get.find<GetProfileService>().getProfile(phone: currentProfilePhone));
    if (myData != null) {
      profile.value = myData;
      isMe.value = true;
    } else {
      await _fetchAndSetProfile(currentProfilePhone!);
      isMe.value = true;
    }
    getUserPosts(currentProfilePhone!);
    isLoading.value = false;
  }

  void loadOtherProfile(String targetPhone) async {
    isLoading.value = true;
    currentProfilePhone = targetPhone;

    await _fetchAndSetProfile(targetPhone);
    await checkIsMe();

    if (!isMe.value) {
      await checkFollowStatus(targetPhone);
    }
    getUserPosts(targetPhone);
    isLoading.value = false;
  }

  void setProfileFromModel(ProfileModel model) async {
    isLoading.value = true;
    profile.value = model;
    currentProfilePhone = model.email;

    await checkIsMe();

    if (!isMe.value) {
      await checkFollowStatus(model.email!);
    }
    if(model.email != null) {
      getUserPosts(model.email!);
    }
    isLoading.value = false;
  }

  Future<void> _fetchAndSetProfile(String phone) async {
    try {
      final data = await Get.find<GetProfileService>().getProfile(phone: phone);
      if (data != null) {
        profile.value = data;
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> getUserPosts(String phone) async {
    isPostsLoading.value = true;
    final res = await ApiHelper.post("Post.aspx",  queryParams: (phone == await PrefHelpers.getUser())
        ? {"emailForMyPost": phone}
        : {"email": phone},);

    if (res.isSuccess) {
      List<PostModel> list = (res.data as List).map((e) => PostModel.fromJson(e)).toList();
      posts.assignAll(list);
    }
    isPostsLoading.value = false;
  }

  bool isVideo(String url) => url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');

  String? getFirstMedia(PostModel post) {
    if (post.video?.isNotEmpty == true) return post.video;
    if (post.image1?.isNotEmpty == true) return post.image1;
    if (post.image2?.isNotEmpty == true) return post.image2;
    if (post.image3?.isNotEmpty == true) return post.image3;
    if (post.image4?.isNotEmpty == true) return post.image4;
    if (post.image5?.isNotEmpty == true) return post.image5;
    return null;
  }

  Future<void> checkIsMe() async {
    String myPhone = await PrefHelpers.getUser() ?? "";
    if (profile.value.email == myPhone) {
      isMe.value = true;
    } else {
      isMe.value = false;
    }
  }

  Future<void> checkFollowStatus(String targetPhone) async {
    String myPhone = await PrefHelpers.getUser() ?? "";
    if (myPhone.isEmpty) return;

    final res = await ApiHelper.post(
      "Follow.aspx",
      queryParams: {"email": myPhone},
    );

    if (res.isSuccess && res.data is List) {
      List<FollowModel> myRelations = (res.data as List).map((e) => FollowModel.fromJson(e)).toList();
      var relation = myRelations.firstWhereOrNull((element) => element.email == myPhone && element.followEmail == targetPhone);

      if (relation != null) {
        if (relation.isAccept == true) {
          followStatus.value = 1;
        } else {
          followStatus.value = 2;
        }
      } else {
        followStatus.value = 0;
      }
    }
  }

  Future<void> reloadProfile() async {
    if (currentProfilePhone != null) {
      await _fetchAndSetProfile(currentProfilePhone!);
      getUserPosts(currentProfilePhone!);
      if (!isMe.value) await checkFollowStatus(currentProfilePhone!);
    }
  }

  Future<void> getFollowLists() async {
    isListLoading.value = true;
    String targetPhone = profile.value.email ?? "";

    final res = await ApiHelper.post("Follow.aspx", queryParams: {"email": targetPhone});
    final res2 = await ApiHelper.post("Follow.aspx", queryParams: {"FollowEmail": targetPhone});

    if (res.isSuccess && res.data is List) {
      final following = (res.data as List)
          .map((e) => FollowModel.fromJson(e))
          .where((e) => e.email == targetPhone)
          .toList();

      final followers = (res2.isSuccess && res2.data is List)
          ? (res2.data as List)
              .map((e) => FollowModel.fromJson(e))
              .where((e) => e.followEmail == targetPhone)
              .toList()
          : <FollowModel>[];

      await Future.wait([
        ...following.map((item) async {
          if (item.followEmail != null) {
            final r = await ApiService.instance.getProfile(email: item.followEmail!);
            item.profileModel = r.data;
          }
        }),
        ...followers.map((item) async {
          if (item.email != null) {
            final r = await ApiService.instance.getProfile(email: item.email!);
            item.profileModel = r.data;
          }
        }),
      ]);

      followingsList.assignAll(following);
      followersList.assignAll(followers);
    }
    isListLoading.value = false;
  }

  // اضافه شدن پشتیبانی از انتخاب حلقه (Circle)
  Future<void> toggleFollow({String? circleId}) async {
    if (isLoading.value) return;
    ApiHelper.showLoading();
    String myPhone = await PrefHelpers.getUser() ?? "";
    String targetPhone = profile.value.email ?? "";

    if (followStatus.value == 1 || followStatus.value == 2) {
      final resList = await ApiHelper.post("Follow.aspx", queryParams: {"email": myPhone});
      if(resList.isSuccess) {
        List<FollowModel> list = (resList.data as List).map((e)=>FollowModel.fromJson(e)).toList();
        var item = list.firstWhereOrNull((e) => e.email == myPhone && e.followEmail == targetPhone);

        if(item != null && item.id != null) {
          await unFollow(item);
          followStatus.value = 0;
          await reloadProfile();
        }
      }
    } else {
      int nextStatus = (profile.value.isPrivate == true) ? 2 : 1;
      followStatus.value = nextStatus;

      // استفاده از سرویس قدیمی که آیدی حلقه رو هندل می‌کنه
      await ApiService.instance.setFollow(
        followEmail: targetPhone,
        circleId: circleId ?? "0", // 0 یعنی بدون حلقه خاص
      );
      await reloadProfile();
      if(isMe.value) getFollowLists();
    }
    ApiHelper.dismissLoading();
  }

  Future<void> unFollow(FollowModel item) async {
    if(followingsList.contains(item)) followingsList.remove(item);
    final res = await ApiHelper.post("DeleteFollow.aspx", queryParams: {"id": item.id.toString()});
    if (!res.isSuccess) {
      if(followingsList.contains(item)) followingsList.add(item);
      FlushHelper.error("حذف انجام نشد");
    } else {
      await reloadProfile();
    }
  }

  Future<void> removeFollower(FollowModel item) async {
    followersList.remove(item);
    final res = await ApiHelper.post("DeleteFollow.aspx", queryParams: {"id": item.id.toString()});
    if (!res.isSuccess) {
      followersList.add(item);
      FlushHelper.error("حذف انجام نشد");
    } else {
      await reloadProfile();
    }
  }

  Future<void> acceptFollow(FollowModel item) async {
    final res = await ApiHelper.post("AcceptFollow.aspx", queryParams: {"id": item.id.toString()});
    if (res.isSuccess) {
      getFollowLists();
      await reloadProfile();
    }
  }

  Future<void> rejectFollow(FollowModel item) async {
    await removeFollower(item);
  }

  bool get canViewContent {
    if (isMe.value) return true;
    if (profile.value.isPrivate == false) return true;
    if (profile.value.isPrivate == true && followStatus.value == 1) return true;
    return false;
  }

  Future<void> deletePost(int postId) async {
    ApiHelper.showLoading();
    final res = await ApiHelper.post("DeletePost.aspx", queryParams: {"id": postId.toString()});
    ApiHelper.dismissLoading();

    if (res.isSuccess) {
      posts.removeWhere((element) => element.id == postId);
      Get.back();
      FlushHelper.success("پست با موفقیت حذف شد");
    } else {
      FlushHelper.error("خطا در حذف پست");
    }
  }
}