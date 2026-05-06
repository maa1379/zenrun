import 'package:get/get.dart';
import '../src/chat_service/chat_controller/api_helper.dart';
import '../core/PrefHelper/PrefHelpers.dart';
import '../src/api_models_repo/models/profile_model.dart';
class GetProfileService extends GetxService {

  static GetProfileService get to => Get.find();

  ProfileModel? myProfile;

  Future<ProfileModel?>? getProfile({String? phone}) async {
    final res = await ApiHelper.post(
      "UserDetailNew.aspx",
      queryParams: {"email": phone ?? await PrefHelpers.getUser()},
    );
    if (res.isSuccess) {
      return ProfileModel.fromJson(res.data[0]);
    } else {
      return null;
    }
  }

  Future<GetProfileService> init() async {
    myProfile = await getProfile();
    return this;
  }
}
