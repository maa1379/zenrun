
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zenrun/services/get_profile_service.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../api_models_repo/models/profile_model.dart';
import '../../api_models_repo/models/story_model.dart';
import '../flush_helper.dart';
import './api_helper.dart';
class StoryController extends GetxController {
  List<StoryModel> storyList = [];
  bool storyLoading = false;
  ProfileModel? myProfile;

  Future<void> getAllStory(bool myStory) async {
    myProfile = await Get.find<GetProfileService>().getProfile();
    final res = await ApiHelper.post(
      "ListStory.aspx",
      disableLoading: true,
      queryParams: myStory
          ? {"email": await PrefHelpers.getUser()}
          : {"myemail": await PrefHelpers.getUser()},
    );

    if (res.isSuccess) {
      List<StoryModel> allStoriesRaw = (res.data as List)
          .where((e) => e != null)
          .map((e) => StoryModel.fromJson(e))
          .toList();
      Map<String, List<StoryModel>> groupedMap = {};

      for (var story in allStoriesRaw) {
        if (story.email != null) {
          if (!groupedMap.containsKey(story.email)) {
            groupedMap[story.email!] = [];
          }
          groupedMap[story.email!]!.add(story);
        }
      }

      storyList.clear();

      // ۳. تبدیل Map به لیست نهایی که قراره نمایش بدیم
      for (var entry in groupedMap.entries) {
        String phone = entry.key;
        List<StoryModel> userStories = entry.value;

        // ساخت یک آبجکت والد که نماینده‌ی اون کاربره
        // (این آبجکت خودش عکس نداره، ولی لیست stories داره)
        StoryModel groupItem = StoryModel(
          email: phone,
          stories: userStories, // لیست تمام عکس/ویدیوهای این کاربر
        );

        // ۴. گرفتن اطلاعات پروفایل (فقط یک بار برای این گروه)
        final profileRes = await ApiHelper.post(
          "UserDetailNew.aspx",
          queryParams: {"email": phone},
        );

        if (profileRes.isSuccess && (profileRes.data as List).isNotEmpty) {
          groupItem.profile = ProfileModel.fromJson(profileRes.data[0]);
        }

        storyList.add(groupItem);
      }

      storyLoading = true;
      update();
    }
  }

  Future<bool> deleteStory(int storyId) async {
    final res = await ApiHelper.post(
      "DeleteStory.aspx",
      queryParams: {"id": storyId.toString()},
      disableLoading: false,
    );
    if (res.isSuccess) {
      await getAllStory(false);
      update();
      FlushHelper.success("حذف استوری انجام شد");
      return true;
    } else {
      FlushHelper.error("حذف استوری انجام نشد");
      return false;
    }
  }

  var isUploading = false.obs;

  Future<void> uploadStory(XFile xFile, String? caption, bool isVideo) async {
    isUploading.value = true;

    try {
      final byte = await xFile.readAsBytes();
      final finalUrl = await ApiHelper.uploadFile(byte, fileName: xFile.name);

      final res = await ApiHelper.post(
        "SetStory.aspx",
        queryParams: {
          "fileURL": finalUrl,
          "email": await PrefHelpers.getUser(),
        },
      );
      if (res.isSuccess) {
        isUploading.value = false;
        Get.back();
        FlushHelper.success("استوری آپلود شد");
        getAllStory(false);
      }
    } catch (e) {
      print("Error uploading: $e");
      FlushHelper.error("خطا در آپلود");
    } finally {
      isUploading.value = false;
    }
  }

  @override
  void onInit() {
    getAllStory(false);
    super.onInit();
  }
}
