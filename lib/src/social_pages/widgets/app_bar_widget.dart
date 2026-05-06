import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart' as badge;
import 'package:flutter/material.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';

import '../../../../core/widgets/Costance.dart';
import '../../../../generated/assets.dart';
import 'package:toln/toln.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  AppBar view(bool isBack, BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      actions: [
        UiHelper.iconBox(
          badge.Badge(
            badgeStyle: const badge.BadgeStyle(badgeColor: ColorsHelper.btn2),
            badgeContent: Text(
              "1".toLn(),
              style: TextStyle(color: Colors.white),
            ),
            showBadge: true,
            child: Image.asset(
              Assets.imagesChat,
              color: Colors.black54,
              height: 25,
            ),
          ),
          () async {
            // Get.find<ChatController>().onInit();
            // Get.toNamed("/chatList");
            // context.to(ChatListScreen());
          },
          color: Colors.transparent,
        ),
        // UiHelper.iconBox(
      ],
      leadingWidth: 130,
      leading: Row(
        children: [
          !isBack
              ? const SizedBox()
              : IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
        ],
      ),
      title: AutoSizeText(
        "Comments",
        maxFontSize: 26,
        minFontSize: 14,
        style: ThemeHelper.textStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }

  AppBar view2() {
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: AutoSizeText(
        "ZenRun",
        maxFontSize: 26,
        minFontSize: 14,
        style: ThemeHelper.textStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return view(true, context);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
