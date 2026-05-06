import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/ai_service.dart';
import 'package:zenrun/src/api_models_repo/models/contact_us_model.dart';
import 'package:zenrun/src/home_pages/pages/main_page.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../core/network/DataState.dart';
import '../../../core/widgets/Costance.dart';
import '../../../services/get_profile_service.dart';
import '../../../services/socket_service.dart';
import '../../api_models_repo/api_service.dart';
import '../../chat_service/chat_controller/chat_global_controller.dart';

class AuthProvider extends ChangeNotifier {
  TextEditingController email = TextEditingController();
  TextEditingController code = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController invitedEmail = TextEditingController();
  TextEditingController age = TextEditingController();
  TextEditingController height = TextEditingController();
  TextEditingController weight = TextEditingController();
  TextEditingController exerciseHours = TextEditingController();
  String? gender;
  bool isSend = false;
  void update() => notifyListeners();


  ContactUsModel? contactUs;
  Future<void> getContactUs()async{
    final res = await ApiService.instance.getContactUs();
    if(res is DataSuccess){
      contactUs = res.data;
      notifyListeners();
    }
  }


  void clean(){
    isSend = false;
    code.clear();
    email.clear();
    phone.clear();
    state.clear();
    city.clear();
    country.clear();
    email.clear();
    height.clear();
    weight.clear();
    age.clear();
    exerciseHours.clear();
    email.clear();
    invitedEmail.clear();
    gender = null;
  }

  Future<void> login(BuildContext context) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.login(
      email: email.text.toLowerCase().toEnglishDigit(),
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      await PrefHelpers.setToken(email.text.toLowerCase().toEnglishDigit());
      code.clear();
      isSend = true;
      notifyListeners();
      ViewHelper.showSuccessDialog(context, "Send verify code to your email");
    } else if (res is DataFailed) {
      ViewHelper.showErrorDialog(context, text: "Please Register in app");
    } else {
      ViewHelper.showErrorDialog(context, text: "Please try again");
    }
  }

  Future<void> register(BuildContext context) async {
    ViewHelper.showLoading();
    await AiService.instance.registerAi(
      username: null,
      city: city.text,
      country: country.text,
      language: "en",
      email: email.text.toEnglishDigit(),
      height: int.parse(height.text),
      weight: int.parse(weight.text),
      password: "@ZenrunApp12345",
      age: int.parse(age.text),
      exerciseHours: int.parse(exerciseHours.text),
      gender: gender?.toLowerCase(),
      name: email.text.toEnglishDigit(),
    );
    final res = await ApiService.instance.sendSms(
      email: email.text.toEnglishDigit(),
      city: city.text,
      country: country.text,
      language: "en",
      phone: phone.text,
      state: state.text,
      invitedEmail: invitedEmail.text,
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      await PrefHelpers.setToken(email.text.toLowerCase().toEnglishDigit());
      code.clear();
      isSend = true;
      notifyListeners();
      ViewHelper.showSuccessDialog(context, "Send verify code to your email");
    } else if (res is DataFailed) {
      ViewHelper.showErrorDialog(context, text: "The email entered is a duplicate");
    } else {
      ViewHelper.showErrorDialog(context, text: "Please try again");
    }
  }

  Future<void> verifySms(BuildContext context) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.verifyOtp(
      email.text.toLowerCase().toEnglishDigit(),
      code.text.toEnglishDigit(),
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess && res.data == "1") {
      await PrefHelpers.setUser(email.text.toLowerCase().toEnglishDigit());
      clean();
      await Get.putAsync(() => GetProfileService().init());
      await Get.putAsync(() => SocketService().init(),permanent: true);
      Get.put(ChatGlobalController(),permanent: true);
      context.rAndRemoveUntilTo(MainPage());
      isSend = false;
    } else if (res is DataFailed) {
      ViewHelper.showErrorDialog(context, text: "Please check your data");
    } else {
      ViewHelper.showErrorDialog(context, text: "Please try again");
    }
  }
}


Future<bool> checkIsMe(String phone) async {
  if (await PrefHelpers.getUser() == phone) {
    return true;
  } else {
    return false;
  }
}