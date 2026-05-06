import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:zenrun/src/social_pages/widgets/add_post_sheet.dart';

import '../../api_models_repo/models/post_model.dart';
import '../chat_controller/profile_controller.dart';
import '../chat_controller/social_controller.dart';
import '../widgets/social_post_item.dart';

class ProfilePostDetailScreen extends StatefulWidget {
  final int initialIndex;
  final List<PostModel> posts;
  final bool isMe;
  // برای دسترسی به متد delete در کنترلر پروفایل
  final ProfileController profileController;

  const ProfilePostDetailScreen({
    super.key,
    required this.initialIndex,
    required this.posts,
    required this.isMe,
    required this.profileController,
  });

  @override
  State<ProfilePostDetailScreen> createState() => _ProfilePostDetailScreenState();
}

class _ProfilePostDetailScreenState extends State<ProfilePostDetailScreen> {
  late PageController _pageController;
  late SocialController _socialController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);

    // اطمینان از وجود سوشیال کنترلر برای مدیریت ویدیوها
    if (Get.isRegistered<SocialController>()) {
      _socialController = Get.find<SocialController>();
    } else {
      _socialController = Get.put(SocialController());
    }
    _socialController.feedPosts.assignAll(widget.posts);

    // راه‌اندازی ویدیو برای پست فعلی (اگر ویدیو باشد)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socialController.onVerticalPageChanged(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // سوشیال کنترلر را حذف نمی‌کنیم چون ممکن است در صفحات دیگر استفاده شود
    // اما ویدیوها را پاز می‌کنیم
    _socialController.pauseAllVideos();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Get.back(),
        ),
        actions: [
          // فقط اگر پروفایل خودم باشد دکمه آپشن را نشان بده
          if (widget.isMe)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
              onPressed: () {
                // دریافت ایندکس فعلی
                final currentIndex = _pageController.page?.round() ?? widget.initialIndex;
                if (currentIndex < widget.posts.length) {
                  _showOptionsBottomSheet(context, widget.posts[currentIndex]);
                }
              },
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        onPageChanged: (index) {
          _socialController.onVerticalPageChanged(index);
        },
        itemBuilder: (context, index) {
          return PostItem(
            post: widget.posts[index],
            index: index,
          );
        },
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, PostModel post) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Gap(20),
            _buildOptionItem(
              icon: Icons.edit_outlined,
              title: "Edit post",
              color: Colors.black87,
              onTap: () {
                Get.back();
                // رفتن به صفحه ادیت با پاس دادن آبجکت پست
                Get.to(
                      () => AddPostSheet(isTask: false),
                  arguments: {"post": post},
                )?.then((result) {
                  // اگر پستی ادیت شد، ریلود کنیم
                  if (result == true) {
                    widget.profileController.reloadProfile();
                  }
                });
              },
            ),
            const Divider(),
            _buildOptionItem(
              icon: Icons.delete_outline_rounded,
              title: "Delete post",
              color: Colors.red,
              onTap: () {
                Get.back();
                _showDeleteConfirmation(context, post);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: color, size: 24),
            const Gap(15),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PostModel post) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.red),
              const Gap(10),
              const Text(
                "Delete post",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Gap(10),
              const Text(
                "آیا از حذف این پست اطمینان دارید؟ این عملیات قابل بازگشت نیست.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("back", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // بستن دیالوگ
                        // فراخوانی متد حذف از کنترلر پروفایل
                        await widget.profileController.deletePost(post.id!);
                        // توجه: کنترلر خودکار صفحه را می‌بندد اگر موفق بود
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Delete", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}