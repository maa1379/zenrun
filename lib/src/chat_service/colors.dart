import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/assets.dart';
import 'flush_helper.dart';

final Color inputColor = Color(0xffdff3f3).withValues(alpha: 0.5);
const Color btn1 = Color(0xff00A98E);
const Color btn2 = Color(0xff009BAB);

class AppColors {
  static const Color primary = Color(0xff00A98E);
  static const Color secondary = Color(0xff009BAB);
  static const Color white = Colors.white;
  static const Color chatBackground = Color(0xffF5F5F5);
  static const Color myMessage = Color(0xffE0F2F1); // نسخه کم‌رنگ شده primary
  static const Color otherMessage = Colors.white;
}

class KeyboardUtil {
  static void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}

final Widget loadingWidget = Center(
  child: Lottie.asset(Assets.animAnimLoading, width: 100),
);

class BtnHelper {
  static Widget mainBtn({required String title, required Function() onTap}) {
    return Container(
      height: Get.height * .055,
      width: Get.width * .9,
      decoration: BoxDecoration(
        borderRadius: .circular(16),
        gradient: LinearGradient(colors: [btn1, btn2]),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: .circular(16),
        child: InkWell(
          borderRadius: .circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: .bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool isNullOrEmpty(dynamic item) {
  if (item == null || item == "") {
    return true;
  } else {
    return false;
  }
}

class UrlLauncherHelper {
  static Future<void> launchedUrl(String? url) async {
    if (await canLaunchUrl(Uri.parse(url ?? ""))) {
      await launchUrl(
        Uri.parse(url ?? ""),
        mode: LaunchMode.externalApplication,
      );
    } else {
      FlushHelper.error("لینک معتبر نمی باشد");
    }
  }
}
