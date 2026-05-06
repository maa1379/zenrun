import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/circle_model.dart'; // مدل حلقه
import 'package:zenrun/src/chat_service/chat_screens/profile_post_detail_screen.dart';
import 'package:zenrun/src/profile_pages/pages/circle_page.dart'; // صفحه حلقه‌ها

import '../../../core/widgets/video_thumbnail_helper.dart';
import '../../api_models_repo/models/profile_model.dart';
import '../../profile_pages/pages/edit_profile_screen.dart';
import '../chat_controller/chat_global_controller.dart';
import '../chat_controller/profile_controller.dart';
import 'chat_screen.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.back});

  final bool? back;

  String _getUniqueTag(dynamic args) {
    if (args is ProfileModel) return args.email ?? "unknown";
    if (args is String) return args;
    return "me";
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    String withBack = Get.parameters['withBack'].toString();
    final String uniqueTag = _getUniqueTag(args);
    final ProfileController controller = Get.put(
      ProfileController(),
      tag: uniqueTag,
    );

    final Color primaryColor = Color(0xff969bff);

    return Scaffold(
      appBar: (withBack == "false" || back == false)
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              centerTitle: true,
              title: Text(
                "Profile",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              shadowColor: Colors.black,
              elevation: 1,
              // actions: [
              //   IconButton(
              //     onPressed: () {
              //       DialogView.showDanger(
              //         context,
              //         "آیا برای خروج از حساب کاربری خود اطمینان دارید؟",
              //         "",
              //             () async {
              //           (await SharedPreferences.getInstance()).clear();
              //           Get.offAllNamed("/login");
              //         },
              //       );
              //     },
              //     icon: Icon(Icons.exit_to_app, color: Colors.red),
              //   ),
              // ],
              leading: (withBack == "false" || back == false)
                  ? SizedBox()
                  : IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                    ),
            ),
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        var user = controller.profile.value;
        bool hasAccess = controller.canViewContent;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildModernHeader(user, args, primaryColor, context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Gap(60),
                      _buildUserInfo(user),
                      const Gap(24),
                      _buildStatsRow(user, controller, uniqueTag),
                      const Gap(24),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMainActionButtons(
                        controller,
                        primaryColor,
                        user,
                        context,
                      ),
                      const Gap(20),
                      if (hasAccess)
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ],
                  ),
                ),
              ),
              hasAccess
                  ? _buildUserPostsGrid(controller)
                  : SliverToBoxAdapter(child: _buildPrivateAccountMessage()),
              const SliverGap(80),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildModernHeader(
    ProfileModel user,
    dynamic args,
    Color color,
    BuildContext context,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 100,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _getUniqueTag(args) != "me"
                        ? IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ),
                            onPressed: () => Get.back(),
                          )
                        : const SizedBox(width: 48),
                    Text(
                      user.username ?? "User",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_box_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Get.toNamed("/addPostScreen"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                width: 100,
                height: 100,
                child: user.image != null
                    ? FastCachedImage(url: user.image!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(ProfileModel user) {
    return Column(
      children: [
        Text(
          "${user.name ?? ''} ${user.family ?? ''}",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const Gap(8),
          Text(
            user.bio!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(
    ProfileModel user,
    ProfileController controller,
    String uniqueTag,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem("Posts", controller.posts.length.toString(), null),
        _verticalDivider(),
        _statItem("Followers", user.followerCount.toString(), () {
          if (controller.canViewContent) {
            Get.to(
              () => FollowListScreen(
                title: "Followers",
                initialIndex: 1,
                tag: uniqueTag,
              ),
            );
          }
        }),
        _verticalDivider(),
        _statItem("Following", user.followingCount.toString(), () {
          if (controller.canViewContent) {
            Get.to(
              () => FollowListScreen(
                title: "Following",
                initialIndex: 0,
                tag: uniqueTag,
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _statItem(String label, String count, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() =>
      Container(height: 20, width: 1, color: Colors.grey[200]);

  // متد نمایش باتم شیت انتخاب حلقه که از فایل profile_screen.dart آورده شده
  Future<String?> _showCircleSelectionSheet(
    BuildContext context,
    List<CircleModel> circles,
  ) {
    return Get.bottomSheet<String?>(
      Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text(
                  "Circles",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: circles.isEmpty
                  ? const Center(child: Text("Is empty."))
                  : ListView.separated(
                      itemCount: circles.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final CircleModel circle = circles[index];
                        return ListTile(
                          title: Text(circle.title ?? ""),
                          onTap: () => Get.back(result: circle.id?.toString()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMainActionButtons(
    ProfileController controller,
    Color color,
    ProfileModel user,
    BuildContext context,
  ) {
    if (controller.isMe.value) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  await context.toCallBack(EditProfileScreen(canPop: true));
                  controller.loadMyProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Edit profile",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () {
                  // انتقال به صفحه حلقه‌ها
                  Get.to(() => CirclePage(email: user.email));
                },
                icon: const Icon(
                  Icons.pie_chart,
                  color: Colors.black87,
                  size: 20,
                ),
                label: const Text(
                  "Circles",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Obx(() {
        int status = controller.followStatus.value;
        bool isFollowed = status != 0;

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    if (status == 0) {
                      if (controller.circleList.isEmpty) {
                        controller.toggleFollow(circleId: "0");
                      } else {
                        String? circleId = await _showCircleSelectionSheet(
                          context,
                          controller.circleList,
                        );
                        if (circleId != null) {
                          controller.toggleFollow(circleId: circleId);
                        }
                      }
                    } else {
                      controller.toggleFollow();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowed ? Colors.grey[100] : color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    status == 1
                        ? "Followed"
                        : (status == 2 ? "Requested" : "Follow"),
                    style: TextStyle(
                      color: isFollowed ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(10),
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black87,
                ),
                onPressed: () async {
                  final chatCtrl = Get.find<ChatGlobalController>();
                  final id = await chatCtrl.syncUserWithChatBackend(
                    user.email ?? "",
                  );
                  if (id != null) {
                    Get.to(
                      () => ChatScreen(
                        targetId: id,
                        isGroup: false,
                        name: user.username ?? "",
                        avatarUrl: user.image,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      });
    }
  }

  Widget _buildUserPostsGrid(ProfileController controller) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 10),
      sliver: Obx(() {
        if (controller.isPostsLoading.value) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        if (controller.posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Gap(40),
                Icon(Icons.grid_on_rounded, size: 60, color: Colors.grey[300]),
                const Gap(10),
                Text(
                  "No posts have been published yet",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = controller.posts[index];
            final media = controller.getFirstMedia(post);
            final bool isVideo = post.video != null && post.video!.isNotEmpty;
            return GestureDetector(
              onTap: () => Get.to(
                () => ProfilePostDetailScreen(
                  initialIndex: index,
                  posts: controller.posts,
                  isMe: controller.isMe.value,
                  profileController: controller,
                ),
              ),
              child: Container(
                color: Colors.grey[200],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // عکس پست (یا کاور ویدیو اگر در API وجود دارد)
                    if (media != null)
                      controller.isVideo(media)
                          ? VideoThumbnailWidget(videoUrl: post.video)
                          : FastCachedImage(url: media, fit: BoxFit.cover)
                    else
                      const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),

                    // آیکون ویدیو
                    if (isVideo)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                    // لیبل Reels یا سفارشی
                    if (post.isReels == true ||
                        (post.label != null && post.label!.isNotEmpty))
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            post.isReels == true ? "Reels" : post.label!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }, childCount: controller.posts.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.5,
            mainAxisSpacing: 1.5,
          ),
        );
      }),
    );
  }

  Widget _buildPrivateAccountMessage() {
    return Column(
      children: [
        const Gap(60),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black87, width: 2),
          ),
          child: const Icon(
            Icons.lock_outline,
            size: 40,
            color: Colors.black87,
          ),
        ),
        const Gap(20),
        const Text(
          "This account is private",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Gap(5),
        Text(
          "You must follow this account to see the posts.",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }
}
