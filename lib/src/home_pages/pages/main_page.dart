import 'package:badges/badges.dart' as badge;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/profile_pages/pages/edit_profile_screen.dart';
import 'package:zenrun/src/profile_pages/pages/wallet_page.dart';
import 'package:zenrun/src/shop_pages/providers/basket_provider.dart';
import 'package:zenrun/src/social_pages/providers/social_provider.dart';

// import 'package:telegram_web_app/telegram_web_app.dart' as tg;
import '../../../generated/assets.dart';
import '../../api_models_repo/ai_service.dart';
import '../../profile_pages/pages/profile_setting_page.dart';
import '../../profile_pages/pages/user_shop_product_history_page.dart';
import '../../profile_pages/providers/profile_provider.dart';
import '../../shop_pages/pages/shop_page.dart';
import '../../social_pages/screens/social_screen.dart';
import '../providers/main_provider.dart';
import 'explore_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // tg.BackButton get backButton => tg.TelegramWebApp.instance.backButton;

  @override
  void initState() {
    if (kIsWeb) {
      // backButton.onClick(onButtonPress);
    }
    checkData();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<BasketProvider>().getAndPushFromDb(context, isPush: false);
    },);
    super.initState();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      // backButton.offClick(onButtonPress);
    }
    super.dispose();
  }

  void checkData() async {
    if (await PrefHelpers.getUser() != null) {
      AiService.instance.loginAi(
        username: await PrefHelpers.getUser(),
        password: "@ZenrunApp12345",
      );
      await context.read<ProfileProvider>().getProfile();
      // await context.read<ProfileProvider>().setFcmProfile();
      await context.read<MainProvider>().getSliders();
      // context.read<SocialProvider>().getNotifList2();
      if (context.read<ProfileProvider>().profile?.username == null ||
          context.read<ProfileProvider>().profile?.username == "") {
        context.rTo(EditProfileScreen(canPop: false));
      }
    }
  }
  DateTime? _lastBackPressTime;
  void _onPopWithResult(bool didPop, Object? result) async {
    if (didPop) return;

    DateTime now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) >
            const Duration(milliseconds: 500)) {
      _lastBackPressTime = now;

      ViewHelper.showWarningDialog(context, "برای خروج دوباره دگمه برگشت را بزنید");

    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: ColorsHelper.white,
          appBar: AppBar(
            backgroundColor: Colors.grey.shade100,
            centerTitle: true,
            leading: provider.activeIndex == 4
                ? UiHelper.iconBox(
              badge.Badge(
                badgeStyle: const badge.BadgeStyle(
                  badgeColor: ColorsHelper.btn2,
                ),
                badgeContent: Text(
                  "1".toLn(),
                  style: TextStyle(color: Colors.white),
                ),
                showBadge: true,
                child: Image.asset(
                  Assets.imagesChat,
                  color: Colors.black54,
                  height: 28,
                ),
              ),
                  () async {
                // context.to(ChatListScreen());
              },
              color: Colors.transparent,
            )
                : provider.activeIndex == 3
                ? Consumer<BasketProvider>(
              builder: (context, provider, child) {
                return UiHelper.iconBox(
                  badge.Badge(
                    badgeStyle: const badge.BadgeStyle(
                      badgeColor: ColorsHelper.btn2,
                    ),
                    badgeContent: Text(
                      provider.badgeCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    showBadge: true,
                    child: Icon(Icons.shopping_cart_outlined,
                        size: 28),
                  ),
                      () async {
                    await provider.getAndPushFromDb(
                      context,
                      isPush: true,
                    );
                  },
                  color: Colors.transparent,
                );
              },
            )
                : provider.activeIndex == 2
                ? IconButton(
              onPressed: () {
                context.to(UserShopProductHistoryPage());
              },
              icon: Icon(Icons.history),
            )
                : IconButton(
              onPressed: () {
                context.to(ProfileSettingPage());
              },
              icon: Icon(Icons.settings, color: Colors.black),
            ),
            title: Text(
              provider.activeIndex == 0
                  ? "ZenRun Ai"
                  : provider.activeIndex == 1
                  ? "Wallet"
                  : provider.activeIndex == 2
                  ? "Explore"
                  : provider.activeIndex == 3
                  ? "Zen Shop"
                  : "Social media",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          bottomNavigationBar: _buildNavBar(),
          body: SizedBox(
            height: 100.h,
            width: 100.w,
            child: PageView(
              controller: provider.pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                HomePage(),
                WalletPage(withScaffold: false),
                ExplorePage(),
                ShopPage(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar() {
    return Consumer<MainProvider>(
      builder: (context, provider, child) {
        return BottomNavigationBar(
          backgroundColor: Colors.grey.shade100,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(color: Colors.blue),
          unselectedLabelStyle: TextStyle(color: Colors.black),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black,
          currentIndex: provider.activeIndex,
          onTap: (value) async {
            if (value == 4) {
              final prefs = await SharedPreferences.getInstance();
              prefs.reload();
              context.to(SocialScreen());
            } else {
              provider.activeIndex = value;
              provider.pageController.jumpToPage(value);
              provider.update();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(Assets.imagesHome, scale: 1.8),
              activeIcon: Image.asset(
                Assets.imagesHome,
                scale: 1.8,
                color: Colors.blue,
              ),
              label: "home",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(Assets.imagesWallet, width: 25),
              activeIcon: Image.asset(
                Assets.imagesWallet,
                width: 25,
                color: Colors.blue,
              ),
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(Assets.imagesMission, scale: 1.8),
              activeIcon: Image.asset(
                Assets.imagesMission,
                scale: 1.8,
                color: Colors.blue,
              ),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(Assets.imagesShopping, height: 26),
              activeIcon: Image.asset(
                Assets.imagesShopping,
                height: 26,
                color: Colors.blue,
              ),
              label: "Shop",
            ),
            BottomNavigationBarItem(
              icon: Consumer<SocialProvider>(
                builder: (context, provider, child) {
                  return badge.Badge(
                    badgeContent: Text(
                      provider.newNotificationsCount.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                    child: Image.asset(
                      Assets.imagesMenu,
                      scale: 1.8,
                      color: Colors.black45,
                    ),
                  );
                },
              ),
              activeIcon: Image.asset(
                Assets.imagesMenu,
                scale: 1.8,
                color: Colors.blue,
              ),
              label: "Social",
            ),
          ],
        );
      },
    );
  }

  void onButtonPress() {
    final snackBar = SnackBar(content: Text('Button pressed'.toLn()));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    context.pop();
  }
}
