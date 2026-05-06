import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/profile_model.dart';
import 'package:zenrun/src/api_models_repo/models/tag_model.dart';

class FollowModel {
  final int? id;
  final String? email;
  final String? followEmail;
  final bool? isAccept;
  final int? circleId;
  ProfileModel? profileModel;
  List<TagModel> tags = [];

  FollowModel({
    this.id,
    this.email,
    this.followEmail,
    this.isAccept,
    this.circleId,
    this.profileModel, // اضافه کردن قابلیت پاس دادن مدل آماده
  }){
    // getData(); <--- این خط حذف شد چون باعث باگ و کندی می‌شود
    // دیتا باید توسط پرووایدر و به صورت گروهی دریافت شود
  }

  // این متد را نگه داشتم تا اگر جای دیگری دستی صدا زده‌اید ارور ندهد
  void getData() async {
    final myEmail = await PrefHelpers.getUser();
    // لاجیک تشخیص اینکه پروفایل کدام سمت را بگیریم
    final targetEmail = (email == myEmail) ? followEmail : email;
    if (targetEmail != null) {
      final res = await ApiService.instance.getProfile(email: targetEmail);
      if (res.data != null) {
        profileModel = res.data;
      }
    }
  }

  factory FollowModel.fromJson(Map<String, dynamic> json) => FollowModel(
    id: json["id"],
    email: json["email"],
    followEmail: json["followEmail"],
    isAccept: json["isAccept"],
    circleId: json["circleId"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "followEmail": followEmail,
    "isAccept": isAccept,
    "circleId": circleId,
  };
}