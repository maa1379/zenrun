import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/generated/assets.dart';
import 'package:zenrun/src/auth_pages/pages/register_page.dart';
import 'package:zenrun/src/auth_pages/pages/step_page.dart';
import 'package:zenrun/src/home_pages/pages/main_page.dart';
import 'package:zenrun/src/home_pages/providers/main_provider.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../core/widgets/nav_helper.dart';
import '../../../services/get_profile_service.dart';
import '../../../services/socket_service.dart';
import '../../chat_service/chat_controller/chat_global_controller.dart';
import '../providers/auth_provider.dart';
// ایمپورت اکستنشن‌های نویگیشن خودتان را چک کنید
// import 'package:zenrun/core/widgets/nav_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    // انیمیشن‌ها
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // شروع منطق بررسی اپلیکیشن
    _handleAppStartup();
  }

  /// متد اصلی تصمیم‌گیری برای نویگیشن
  Future<void> _handleAppStartup() async {
    // ۱. دریافت اطلاعات مورد نیاز (همزمان برای سرعت بیشتر)
    // هم ۳ ثانیه صبر می‌کنیم (برای زیبایی اسپلش) و هم دیتا را چک می‌کنیم
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)), // تاخیر اجباری UI
      PrefHelpers.getUser(), // وضعیت لاگین
      AppLinks().getInitialLink(), // بررسی دیپ‌لینک اولیه
      // context.read<AuthProvider>().getContactUs() // اگر این متد فیوچر است اینجا بگذارید
    ]);

    // اگر context نامعتبر شده (مثلا کاربر بک زده)، ادامه نده
    if (!mounted) return;

    final user = results[1]; // نتیجه getUser
    final Uri? initialUri = results[2] as Uri?; // نتیجه getInitialLink

    // ۲. بررسی دیپ‌لینک (اولویت اول)
    if (user == null && initialUri != null) {
      String path = initialUri.path;
      if (path.endsWith('/')) path = path.substring(0, path.length - 1);

      if (path == '/invite') {
        final email = initialUri.queryParameters['inviteEmail'];
        // هدایت مستقیم به صفحه ثبت نام با ایمیل
        context.rAndRemoveUntilTo(RegisterPage(inviteEmail: email ?? ""));
        return; // کار تمام است، بقیه کد اجرا نشود
      }
    }else if (user == null) {
      // کاربر لاگین نیست -> صفحه استپ/ورود
      context.rAndRemoveUntilTo(const StepPage(inviteEmail: "",));
    } else {
      // کاربر لاگین است -> لود اطلاعات و رفتن به خانه
      await context.read<MainProvider>().loadStepsFromPrefs();
      await Get.putAsync(() => GetProfileService().init());
      // await context.read<ProfileProvider>().setFcmProfile();
      await Get.putAsync(() => SocketService().init(),permanent: true);
      Get.put(ChatGlobalController(),permanent: true);
      if (mounted) {
        context.rAndRemoveUntilTo(const MainPage());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 100.w,
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    Assets.imagesMap,
                    width: 100.w,
                    fit: BoxFit.cover,
                    color: Colors.orange.shade200,
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
                child: Image.asset(Assets.imagesLogo, width: 400, height: 400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}