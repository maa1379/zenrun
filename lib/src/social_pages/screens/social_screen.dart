import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/social_pages/providers/social_provider.dart';

import '../../../../core/widgets/Costance.dart';
import '../../../../generated/assets.dart';
import '../../../core/widgets/custom_sacffold.dart';
import '../../chat_service/chat_controller/social_controller.dart';
import '../../chat_service/chat_screens/create_story.dart';
import '../../chat_service/chat_screens/inbox_screen.dart';
import '../../chat_service/chat_screens/notification_screen.dart';
import '../../chat_service/chat_screens/profile_screen.dart';
import '../../chat_service/chat_screens/social_list_feed_screen.dart';
import '../../chat_service/chat_screens/social_post_screen.dart';
import '../widgets/add_post_sheet.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {

  @override
  void initState() {
    final provider = context.read<SocialProvider>();
    provider.pageController = PageController(initialPage: 0);
    provider.activePage = 0;
    super.initState();
  }

  @override
  void dispose() {
    if (Get.isRegistered<SocialController>()) {
      Get.find<SocialController>().pauseAllVideos();
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(20),
        child: FloatingActionButton(
          onPressed: () {
            showCupertinoSheet(
              context: context,
              builder: (BuildContext context) {
                return AddPostSheet(isTask: false);
              },
              enableDrag: true,
            );
          },
          backgroundColor: ColorsHelper.btn2,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
      title: "ZenRun Social",
      leading: Row(
        children: [
          IconButton(
            onPressed: () {
              context.pop();
            },
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Get.toNamed("/searchUserScreen");
            },
            icon: Image.asset(Assets.imagesSearch, width: 22),
          ),
        ],
      ),
      actions: Row(
        children: [
          NotificationBadgeButton(),
          IconButton(
            onPressed: () async {
              Get.to(CreateStoryView());
            },
            icon: Column(
              spacing: 2,
              children: [
                Image.asset(Assets.imagesStories, width: 22),
                Text("Story".toLn(), style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<SocialProvider>(
        builder: (context, provider, child) {
          return PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: provider.pageController,
            children: [
              const SocialListFeedScreen(), // 0: تب خانه (فید جدید)
              const SocialReelsScreen(),
              InboxScreen(),
              ProfileScreen(back: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavBar() {
    return Consumer<SocialProvider>(
      builder: (context, provider, child) {
        return Container(
          width: 100.w,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10,
                offset: Offset(0, -0.5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  Assets.imagesPosts,
                  color: Colors.black,
                  width: 25,
                ),
                activeIcon: Image.asset(
                  Assets.imagesPosts,
                  color: ColorsHelper.btn2,
                  width: 25,
                ),
                label: "Posts",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  Assets.imagesPosts,
                  color: Colors.black,
                  width: 25,
                ),
                activeIcon: Image.asset(
                  Assets.imagesReels,
                  color: ColorsHelper.btn2,
                  width: 25,
                ),
                label: "Reels",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  Assets.imagesChat,
                  color: Colors.black,
                  width: 25,
                ),
                activeIcon: Image.asset(
                  Assets.imagesChat,
                  color: ColorsHelper.btn2,
                  width: 25,
                ),
                label: "Chats",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  Assets.imagesProfile,
                  color: Colors.black,
                  width: 25,
                ),
                activeIcon: Image.asset(
                  Assets.imagesProfile,
                  color: ColorsHelper.btn2,
                  width: 25,
                ),
                label: "Profile",
              ),
            ],
            onTap: (index) {
              if (provider.activePage != index) {
                if (Get.isRegistered<SocialController>()) {
                  final socialCtrl = Get.find<SocialController>();

                  // 🌟 ۱. آپدیت کردن تب فعال در کنترلر
                  socialCtrl.activeTab = index;

                  // 🌟 ۲. اول همه ویدیوها قطع شوند
                  socialCtrl.pauseAllVideos();

                  // 🌟 ۳. پخش ویدیوی مخصوص همان تبی که واردش شدیم
                  if (index == 0) {
                    String key = "feed_${socialCtrl.currentFeedIndex.value}_0";
                    final vCtrl = socialCtrl.videoControllers[key];
                    if (vCtrl != null && vCtrl.controller.value.isInitialized) {
                      vCtrl.controller.play();
                    }
                  } else if (index == 1) {
                    String key = "reel_${socialCtrl.currentReelIndex.value}_0";
                    final vCtrl = socialCtrl.videoControllers[key];
                    if (vCtrl != null && vCtrl.controller.value.isInitialized) {
                      vCtrl.controller.play();
                    }
                  }
                }

                provider.activePage = index;
                provider.pageController.jumpToPage(index);
                provider.update();
              }
            },
            selectedFontSize: 12,
            backgroundColor: Colors.white,
            selectedItemColor: ColorsHelper.black,
            currentIndex: provider.activePage,
          ),
        );
        // return RNavNSheet(
        //   backgroundColor: provider.activePage == 1
        //       ? Colors.white
        //       : Colors.transparent,
        //   sheetOpenIcon: Icons.post_add,
        //   sheetOpenIconBoxColor: ColorsHelper.btn2,
        //   sheetOpenIconColor: ColorsHelper.white,
        //   sheetCloseIcon: Icons.close,
        //   onSheetToggle: (value) {
        //     showCupertinoSheet(
        //       context: context,
        //       builder: (BuildContext context) {
        //         return AddPostSheet(label: "Post");
        //       },
        //       enableDrag: true,
        //     );
        //   },
        //   sheet: SizedBox(),
        //   borderColors: [ColorsHelper.btn1, ColorsHelper.btn2],
        //   initialSelectedIndex: provider.activePage,
        //   onTap: (index) {
        //     if (provider.activePage != index) {
        //       _pauseAllVideos(provider);
        //       provider.activePage = index;
        //       provider.pageController.jumpToPage(index);
        //       provider.update();
        //     }
        //   },
        //   selectedItemColor: ColorsHelper.btn2,
        //   items: [
        //     RNavItem(
        //       image: Image.asset(
        //         Assets.imagesPosts,
        //         color: Colors.black,
        //         width: 20,
        //       ),
        //       activeImage: Image.asset(
        //         Assets.imagesPosts,
        //         color: ColorsHelper.btn2,
        //         width: 25,
        //       ),
        //       label: "Posts",
        //     ),
        //     RNavItem(
        //       image: Image.asset(
        //         Assets.imagesReels,
        //         color: Colors.black,
        //         width: 20,
        //       ),
        //       activeImage: Image.asset(
        //         Assets.imagesReels,
        //         color: ColorsHelper.btn2,
        //         width: 25,
        //       ),
        //       label: "Reels",
        //     ),
        //     RNavItem(
        //       image: Image.asset(
        //         Assets.imagesChat,
        //         color: Colors.black,
        //         width: 20,
        //       ),
        //       activeImage: Image.asset(
        //         Assets.imagesChat,
        //         color: ColorsHelper.btn2,
        //         width: 25,
        //       ),
        //       label: "Chats",
        //     ),
        //     RNavItem(
        //       image: Image.asset(
        //         Assets.imagesProfile,
        //         color: Colors.black,
        //         width: 20,
        //       ),
        //       activeImage: Image.asset(
        //         Assets.imagesProfile,
        //         color: ColorsHelper.btn2,
        //         width: 25,
        //       ),
        //       label: "Profile",
        //     ),
        //   ],
        // );
      },
    );
  }
}
