import 'dart:io';

import 'package:battery_optimization_helper/battery_optimization_helper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/main.dart';
import 'package:zenrun/src/home_pages/providers/pedometer_service.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';

import '../../../generated/assets.dart';
import '../../../plugins/tanafos/splash_2_screen.dart';
import '../../ai_pages/pages/ai_text_page.dart';
import '../../profile_pages/providers/profile_provider.dart';
import '../providers/main_provider.dart';
import '../widgets/pedometer_chart_widget.dart';
import '../widgets/social_chart_widget.dart';
import '../widgets/task_chart_widget.dart';
import 'mission_page.dart';
import 'music_player_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getData();
    BatteryOptimizerHelper.checkAndRequestOptimization();
  }

  void getData() async {
    Future.microtask(() async {
      _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {});
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});

      context.read<TaskProvider>().fetchAllData();
      context.read<HealthData>().refreshData();

      final user = await PrefHelpers.getUser();
      if (mounted) {
        context.read<ProfileProvider>().fetchProfileData(context, user);
      }
    });
    ViewHelper.dismissLoading();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      context.read<HealthData>().refreshData();
    }
  }

  // متد کمکی برای تبدیل کدهای رنگ از سرور
  Color _parseColor(String? hexColor, Color fallback) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      String cleanHex = hexColor.replaceAll('#', '').toLowerCase();
      if (cleanHex.length == 6) cleanHex = "ff$cleanHex";
      if (cleanHex.startsWith("0x")) cleanHex = cleanHex.substring(2);
      return Color(int.parse("0x$cleanHex"));
    } catch (e) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // بک‌گراند نرم‌تر
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: RefreshIndicator(
          color: ColorsHelper.btn2,
          onRefresh: () async {
            final email = await PrefHelpers.getUser();
            await Future.wait([
              context.read<MainProvider>().loadStepsFromPrefs(),
              context.read<TaskProvider>().fetchAllData(),
              context.read<ProfileProvider>().fetchProfileData(context, email),
              context.read<MainProvider>().getSliders(),
            ]);
            BatteryOptimizerHelper.checkAndRequestOptimization();
            await context.read<HealthData>().refreshData();
            setState(() {});
          },
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            children: [
              _buildTopCoinsBar(),
              Gap(3.h),

              _buildCarouselSlider(),
              Gap(3.h),

              _buildSectionTitle("Daily Activity"),
              Gap(2.h),
              _buildActivityRow(),
              Gap(3.h),

              _buildAiButton(context),
              Gap(3.h),

              _buildCategoriesSection(),
              Gap(3.h),

              _buildRelaxBanner(context),
              Gap(4.h), // فضای خالی پایین برای راحتی اسکرول
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }

  /// ------------------------------------------------------------------
  /// Components Builders
  /// ------------------------------------------------------------------

  Widget _buildTopCoinsBar() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCoinChip(Assets.imagesC1, provider.profile?.sCoin?.toString().seRagham() ?? "0"),
            _buildCoinChip(Assets.imagesC2, provider.profile?.rCoin?.toString().seRagham() ?? "0"),
            _buildCoinChip(Assets.imagesC3, provider.profile?.zCoin?.toString().seRagham() ?? "0"),
          ],
        );
      },
    );
  }

  Widget _buildCoinChip(String asset, String amount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 22),
          Gap(6),
          Text(
            amount.toLn(),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return Consumer<MainProvider>(
      builder: (context, provider, child) {
        if (!provider.loading) {
          return SizedBox(
            height: 20.h,
            child: Center(child: UiHelper.showLoading()),
          );
        }
        if (provider.sliderList.isEmpty) return const SizedBox();

        return CarouselSlider(
          options: CarouselOptions(
            height: 20.h,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 1.0, // برای اینکه تمام عرض را پر کند
          ),
          items: provider.sliderList.map((i) {
            return GestureDetector(
              onTap: () async {
                if (i.linkEn != null && i.linkEn!.isNotEmpty) {
                  await launchUrl(Uri.parse(i.linkEn!), mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                    ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FastCachedImage(
                    url: i.imageEn ?? "",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toLn(),
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildActivityRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        SocialChart(),
        TaskCharts(),
        DailyProgressWidget(),
      ],
    );
  }

  Widget _buildAiButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.to(AiTextPage()),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            Gap(10),
            Text(
              "Talking with AI".toLn(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds, delay: 1.seconds);
  }

  Widget _buildCategoriesSection() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.faslList.isEmpty) return const SizedBox();

        // استفاده از firstWhereOrNull برای جلوگیری از کرش شدن اپلیکیشن اگر اسم‌ها در سرور تغییر کرد
        final item1 = provider.faslList.firstWhereOrNull((e) => e.title == "Daily");
        final item2 = provider.faslList.firstWhereOrNull((e) => e.title == "Natural Music");
        final item3 = provider.faslList.firstWhereOrNull((e) => e.title == "Longevity Insights");

        return Column(
          children: [
            Row(
              children: [
                if (item1 != null)
                  Expanded(child: _buildCategoryCard(item1, Colors.blue.shade400)),
                if (item1 != null && item2 != null) Gap(15),
                if (item2 != null)
                  Expanded(child: _buildCategoryCard(item2, Colors.teal.shade400)),
              ],
            ),
            if (item3 != null) ...[
              Gap(15),
              _buildCategoryCardHorizontal(item3, Colors.orange.shade400),
            ]
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(dynamic item, Color fallbackColor) {
    final bgColor = _parseColor(item.color, fallbackColor);
    return GestureDetector(
      onTap: () {
        final regex = RegExp(r'(موزیک|music)', caseSensitive: false);
        if (regex.hasMatch(item.title ?? "")) {
          context.to(
            MusicPlayerScreen(
              taskList: item.taskList ?? [],
              title: item.title ?? "",
              faslModel: item,
            ),
          );
        } else {
          context.to(
            MissionPage(
              taskList: item.taskList ?? [],
              title: item.title ?? "",
              faslModel: item,
            ),
          );
        }
      },
      child: Container(
        height: 20.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [bgColor.withOpacity(0.7), bgColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.image != null && item.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FastCachedImage(url: item.image!, width: 70, height: 70, fit: BoxFit.cover),
              ),
            Gap(12),
            Text(
              item.title ?? "",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCardHorizontal(dynamic item, Color fallbackColor) {
    final bgColor = _parseColor(item.color, fallbackColor);
    return GestureDetector(
      onTap: () => context.to(MissionPage(taskList: item.taskList ?? [], title: item.title ?? "", faslModel: item)),
      child: Container(
        height: 12.h,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [bgColor.withOpacity(0.8), bgColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.title ?? "",
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (item.image != null && item.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FastCachedImage(url: item.image!, width: 70, height: 70, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelaxBanner(BuildContext context) {
    return Container(
      height: 20.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.asset(Assets.imagesRelax, fit: BoxFit.cover, height: double.infinity),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Time to relax".toLn(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Gap(12),
                  InkWell(
                    onTap: () => context.to(Splash2Screen()),
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                          color: ColorsHelper.btn2,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: ColorsHelper.btn2.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 3))]
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BatteryOptimizerHelper {
  static Future<void> checkAndRequestOptimization() async {
    if (!Platform.isAndroid) return;

    final isEnabled = await BatteryOptimizationHelper.isBatteryOptimizationEnabled();
    if (!isEnabled) return;

    final proceed = await showDialog<bool>(
      context: navKey.currentContext!,
      builder: (ctx) => AlertDialog(
        title: const Text('Background Execution'),
        content: const Text(
          'To run reliably in the background, the app requests an exception from '
              'battery optimizations. You can change this in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorsHelper.btn2, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      await BatteryOptimizationHelper.ensureOptimizationDisabled(
        openSettingsIfDirectRequestNotPossible: true,
      );
    }
  }
}