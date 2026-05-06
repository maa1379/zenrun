import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller/social_controller.dart';
import '../widgets/social_post_item.dart';

class SocialReelsScreen extends StatefulWidget {
  const SocialReelsScreen({super.key});

  @override
  State<SocialReelsScreen> createState() => _SocialReelsScreenState();
}

class _SocialReelsScreenState extends State<SocialReelsScreen> {
  final SocialController controller = Get.put(SocialController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ریلز معمولاً پس زمینه مشکی دارد
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00A79B)));
        }
        if(controller.reelsPosts.isEmpty){
          return Center(child: Text("Empty",style: TextStyle(color: Colors.white),),);
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          controller: controller.reelsPageController,
          itemCount: controller.reelsPosts.length,
          onPageChanged: controller.onReelPageChanged,
          itemBuilder: (context, index) {
            final post = controller.reelsPosts[index];
            return ExcludeSemantics( // 🌟 جلوگیری از کرش مشابه در ریلز
              child: PostItem(
                key: ValueKey('reel_${post.id ?? index}'), // 🌟 کلید یکتا
                post: post,
                index: index,
                isReel: true, // <--- تنظیم به عنوان ریلز
              ),
            );
          },
        );
      }),
    );
  }
}