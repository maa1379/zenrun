import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../chat_controller/social_controller.dart';
import '../chat_controller/story_controller.dart' as story;
import '../widgets/social_post_item.dart';
import 'story_list_view.dart';

class SocialListFeedScreen extends StatefulWidget {
  const SocialListFeedScreen({super.key});

  @override
  State<SocialListFeedScreen> createState() => _SocialListFeedScreenState();
}

class _SocialListFeedScreenState extends State<SocialListFeedScreen> {
  final SocialController controller = Get.put(SocialController());

  @override
  void initState() {
    super.initState();
    if (controller.feedPosts.isEmpty) {
      controller.fetchInitialFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.feedPosts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A79B)),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchInitialFeed();
            Get.find<story.StoryController>().getAllStory(false);
          },
          color: const Color(0xFF00A79B),
          backgroundColor: Colors.white,
          child: ListView.builder(
            itemCount: controller.feedPosts.length + 1, // +1 برای استوری‌ها در بالای لیست
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    StoryListView(), // استوری‌ها فقط در بالای این لیست نمایش داده می‌شوند
                    const Divider(thickness: 1, color: Colors.grey),
                  ],
                );
              }

              final postIndex = index - 1;
              final post = controller.feedPosts[postIndex]; // 🌟 گرفتن پست فعلی

              // 🌟 ExcludeSemantics جلوی کرش‌های مربوط به رندر و اسکرول سریع را می‌گیرد
              return ExcludeSemantics(
                child: VisibilityDetector(
                  // 🌟 استفاده از آیدی یکتای پست به جای ایندکس
                  key: Key('feed_post_${post.id ?? postIndex}'),
                  onVisibilityChanged: (visibilityInfo) {
                    // اگر بیش از 60 درصد پست در صفحه بود، پخشش کن و اطلاعات رو بگیر
                    if (visibilityInfo.visibleFraction > 0.6) {
                      controller.onFeedItemVisible(postIndex);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PostItem(
                      post: post,
                      index: postIndex,
                      isReel: false, // <--- تنظیم به عنوان فید
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}