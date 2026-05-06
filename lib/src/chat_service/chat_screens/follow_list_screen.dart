import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:zenrun/core/widgets/Costance.dart';

import '../../../services/get_profile_service.dart';
import '../../api_models_repo/models/follow_model.dart';
import '../chat_controller/profile_controller.dart';
import '../colors.dart';

class FollowListScreen extends StatefulWidget {
  final int initialIndex;
  final String title;
  final String tag;

  const FollowListScreen({
    super.key,
    this.initialIndex = 0,
    required this.title,
    required this.tag,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProfileController controller;
  final tealColor = const Color(0xff969bff);

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>(tag: widget.tag);
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    controller.getFollowLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: btn1),
          onPressed: () => Get.back(),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                controller: _tabController,
                indicatorColor: tealColor, // اصلاح رنگ
                labelColor: tealColor,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  const Tab(text: "Following"),
                  const Tab(text: "Followers"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFollowingsList(), // تب ۲
            _buildFollowersList(),  // تب ۱
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersList() {
    return Obx(() {
      if (controller.isListLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.followersList.isEmpty) return _emptyState("You have no followers yet");

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: controller.followersList.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final item = controller.followersList[index];

          // فالوور: کسی که منو فالو کرده (username/userimage)
          // شماره‌اش میشه: phone
          return _buildUserRow(
            model: item,
            phone: item.email,
            name: item.profileModel?.name != null
                ? "${item.profileModel!.name} ${item.profileModel!.family ?? ''}".trim()
                : item.email,
            image: item.profileModel?.image,
            isFollowerTab: true,
          );
        },
      );
    });
  }

  Widget _buildFollowingsList() {
    return Obx(() {
      if (controller.isListLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.followingsList.isEmpty) return _emptyState("You are not following anyone");

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: controller.followingsList.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final item = controller.followingsList[index];

          // فالوینگ: کسی که من فالوش کردم (followusername/followuserimage)
          // شماره‌اش میشه: followPhone
          return _buildUserRow(
            model: item,
            phone: item.followEmail,
            name: item.profileModel?.name != null
                ? "${item.profileModel!.name} ${item.profileModel!.family ?? ''}".trim()
                : item.followEmail,
            image: item.profileModel?.image,
            isFollowerTab: false,
          );
        },
      );
    });
  }

  Widget _buildUserRow({
    required FollowModel model,
    required String? name,
    required String? image,
    required String? phone, // شماره پروفایل هدف برای نویگیشن
    required bool isFollowerTab,
  }) {
    String displayName = name?.toString() ?? phone?.replaceRange(4, 8, "****").toPersianDigit() ?? "User";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // عکس پروفایل با قابلیت کلیک
          GestureDetector(
            onTap: () async {
              if (phone == null) return;
              ViewHelper.showLoading();
              try {
                final profile = await Get.find<GetProfileService>().getProfile(phone: phone);
                ViewHelper.dismissLoading();
                if (profile != null) {
                  Get.toNamed("profileScreen", arguments: profile, parameters: {"withBack": "true"});
                }
              } catch (e) {
                ViewHelper.dismissLoading();
                // هندل خطا
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: SizedBox(
                width: 50, height: 50,
                child: FastCachedImage(
                  url: image ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.grey)
                  ),
                ),
              ),
            ),
          ),
          const Gap(12),
          // نام کاربر
          Expanded(
            child: Text(
              displayName,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // دکمه‌های عملیاتی (فقط اگر لیست خودم را می‌بینم)
          if (controller.isMe.value) ...[
            if (isFollowerTab) ...[
              // تب فالوورها
              if (model.isAccept == true)
                _buildActionButton(
                  text: "Delete",
                  bgColor: Colors.white,
                  textColor: Colors.redAccent,
                  isOutlined: true,
                  onTap: () => controller.removeFollower(model),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      text: "Accept",
                      bgColor: tealColor,
                      textColor: Colors.white,
                      isOutlined: false,
                      width: 60,
                      onTap: () => controller.acceptFollow(model),
                    ),
                    const Gap(8),
                    _buildActionButton(
                      text: "Reject",
                      bgColor: Colors.white,
                      textColor: Colors.red,
                      isOutlined: true,
                      width: 50,
                      onTap: () => controller.rejectFollow(model),
                    ),
                  ],
                )
            ] else ...[
              // تب فالووینگ‌ها
              _buildActionButton(
                text: "UnFollow",
                bgColor: Colors.grey[200]!,
                textColor: Colors.black87,
                isOutlined: false,
                onTap: () => controller.unFollow(model),
              ),
            ]
          ]
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required bool isOutlined,
    required VoidCallback onTap,
    double width = 85,
  }) {
    return SizedBox(
      height: 32,
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          side: isOutlined ? BorderSide(color: textColor.withOpacity(0.5)) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
          const Gap(10),
          Text(text, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}