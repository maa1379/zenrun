import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../core/network/DataState.dart';
import '../../../core/widgets/extetions.dart';
import '../../api_models_repo/api_service.dart';
import '../../api_models_repo/models/follow_model.dart';
import '../../api_models_repo/models/notif_model.dart';
import '../../api_models_repo/models/profile_model.dart';
import '../flush_helper.dart';
import './api_helper.dart';
class NotificationController extends GetxController {
  var notificationList = <NotifModel>[].obs;
  var isLoading = false.obs;
  var unseenCount = 0.obs;
  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // Future<void> fetchNotifications() async {
  //   isLoading.value = true;
  //
  //   final phone = await PrefHelpers.getUser();
  //
  //   final res = await ApiHelper.post("Notif.aspx",queryParams: {
  //     "receiverPhone":phone,
  //   });
  //   if (res.isSuccess) {
  //     List<NotifModel> fetchedData = [];
  //     fetchedData.addAll((res.data as List).toListModel(NotifModel.fromJson));
  //     fetchedData.removeWhere((element) => element.receiverEmail == element.senderEmail,);
  //     fetchedData.sort((a, b) => b.id!.compareTo(a.id!));
  //     notificationList.assignAll(fetchedData);
  //     await _calculateUnseenCount();
  //   }
  //   isLoading.value = false;
  // }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    final res = await ApiService.instance.getNotifList();
    if (res is DataSuccess) {
      final allNotifs = res.data ?? [];
      final currentUserEmail = await PrefHelpers.getUser();
      notificationList.value = allNotifs
          .where((n) => n.senderEmail != currentUserEmail)
          .toList();

      final userEmails = notificationList.map((n) => n.email).nonNulls.toSet();

      final profileFutures = userEmails
          .map((email) => ApiService.instance.getProfile(email: email))
          .toList();

      final profilesRes = await Future.wait(profileFutures);

      final profiles = profilesRes
          .whereType<DataSuccess<ProfileModel>>()
          .map((res) => res.data)
          .nonNulls
          .toList();

      final profileMap = {for (var p in profiles) p.email: p};

      for (var notif in notificationList) {
        notif.profileModel = profileMap[notif.email];
      }
      notificationList.removeWhere((element) => element.receiverEmail == element.senderEmail,);
      notificationList.sort((a, b) => b.id!.compareTo(a.id!));
    await _calculateUnseenCount();
    isLoading.value = false;
    }
  }



  Future<void> _calculateUnseenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenId = prefs.getInt('last_seen_notification_id') ?? 0;

    int count = 0;
    for (var item in notificationList) {
      if (item.id != null && item.id! > lastSeenId) {
        count++;
      }
    }
    unseenCount.value = count;
  }

  Future<void> markNotificationsAsSeen() async {
    if (notificationList.isEmpty) return;
    final newestId = notificationList.first.id ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final currentSavedId = prefs.getInt('last_seen_notification_id') ?? 0;

    if (newestId > currentSavedId) {
      await prefs.setInt('last_seen_notification_id', newestId);
    }
    unseenCount.value = 0;
  }

  // --- متدهای جدید برای هندل کردن درخواست فالو ---

  Future<void> acceptFollowRequest(int id,String senderPhone) async {
    ApiHelper.showLoading();
    final followRecord = await ApiHelper.post(
      "Follow.aspx",
      queryParams: {"FollowPhone": await PrefHelpers.getUser()},
    );
    if (followRecord.isSuccess) {
      List<FollowModel> myRelations = (followRecord.data as List)
          .map((e) => FollowModel.fromJson(e))
          .toList();
      final followId = myRelations
          .firstWhereOrNull((f) => f.email == senderPhone)
          ?.id
          .toString();
    // 1. تایید درخواست
    final res = await ApiHelper.post("AcceptFollow.aspx", queryParams: {"id": followId});

    if (res.isSuccess) {
      // 2. حذف اعلان بعد از تایید موفق
      await deleteNotification(id, showMessage: false);
      FlushHelper.success("درخواست با موفقیت تایید شد");
    } else {
      FlushHelper.error("خطا در تایید درخواست");
    }
    ApiHelper.dismissLoading();
    }
  }

  Future<void> deleteNotification(int id, {bool showMessage = true}) async {
    // حذف اعلان (چه برای رد کردن، چه تمیزکاری بعد از تایید)
    final res = await ApiHelper.post("DeleteNotif.aspx", queryParams: {"id": id.toString()});

    if (res.isSuccess) {
      notificationList.removeWhere((element) => element.id == id);
      if (showMessage) FlushHelper.success("اعلان حذف شد");
    } else {
      if (showMessage) FlushHelper.error("خطا در حذف اعلان");
    }
  }

}