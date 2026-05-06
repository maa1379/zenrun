import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/dialog_view.dart';
import '../../../generated/assets.dart';
import '../../api_models_repo/models/story_model.dart';
import '../../auth_pages/providers/auth_provider.dart';
import '../chat_controller/story_controller.dart' as story;
import 'create_story.dart';
import 'package:story_view/story_view.dart';

class StoryListView extends StatelessWidget {
  StoryListView({super.key});

  final c = Get.put(story.StoryController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<story.StoryController>(
      builder: (controller) {
        return SizedBox(
          width: Get.width,
          height: Get.height * .1,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: .start,
              crossAxisAlignment: .center,
              children: [
                // --- آیتم اول (پروفایل خود کاربر) ---
                controller.storyList.any((element) => element.email == controller.myProfile?.email,)?SizedBox():Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: InkWell(
                    onTap: () async {
                      StoryModel? myStory;
                      // ۱. جستجو در لیست استوری‌ها برای پیدا کردن استوری خود کاربر
                      for (var item in controller.storyList) {
                        bool isMe = await checkIsMe(item.email ?? "");
                        if (isMe) {
                          myStory = item;
                          break;
                        }
                      }
                      // ۲. بررسی وجود استوری
                      if (myStory != null && myStory.stories != null && myStory.stories!.isNotEmpty) {
                        // اگر استوری داشت، استوریش رو پخش کن
                        Get.to(
                              () => StoryPlayerView(
                            stories: myStory!.stories!,
                            userName: myStory.profile?.username ?? "",
                            userImage: myStory.profile?.image ?? "",
                            isMe: true, // حتما true پاس داده میشه تا دکمه حذف براش کار کنه
                          ),
                        );
                      } else {
                        // اگر استوری نداشت، بره برای ساخت استوری جدید
                        Get.to(() => const CreateStoryView());
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                  (controller.myProfile?.image == null ||
                                      controller.myProfile!.image!.isEmpty)
                                      ? const AssetImage(
                                    Assets.imagesLogo,
                                  )
                                  as ImageProvider
                                      : FastCachedImageProvider(
                                    controller.myProfile!.image!,
                                  ),
                                ),
                              ),
                            ),
                            // آیکون پلاس
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(
                                    BorderSide(color: Colors.white, width: 2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15,),
                      ],
                    ),
                  ),
                ),

                // --- لیست استوری بقیه کاربرا ---
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.storyList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    itemBuilder: (context, index) {
                      final item = controller.storyList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: InkWell(
                          onTap: () async {
                            bool isMe = await checkIsMe(item.email ?? "");
                            if (item.stories != null &&
                                item.stories!.isNotEmpty) {
                              Get.to(
                                    () => StoryPlayerView(
                                  stories: item.stories!,
                                  userName: item.profile?.username ?? "",
                                  userImage: item.profile?.image ?? "",
                                  isMe: isMe,
                                ),
                              );
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFfeda75),
                                      Color(0xFFfa7e1e),
                                      Color(0xFFd62976),
                                      Color(0xFF962fbf),
                                      Color(0xFF4f5bd5),
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                    (item.profile?.image == null ||
                                        item.profile!.image!.isEmpty)
                                        ? const AssetImage(
                                      Assets.imagesLogo,
                                    )
                                    as ImageProvider
                                        : FastCachedImageProvider(
                                      item.profile!.image!,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                item.profile?.username ?? "",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StoryPlayerView extends StatefulWidget {
  final List<StoryModel> stories;
  final String userName;
  final String userImage;
  final bool isMe;

  const StoryPlayerView({
    super.key,
    required this.stories,
    required this.userName,
    required this.userImage,
    required this.isMe,
  });

  @override
  State<StoryPlayerView> createState() => _StoryPlayerViewState();
}

class _StoryPlayerViewState extends State<StoryPlayerView> {
  final StoryController storyViewController = StoryController();

  final logicController = Get.find<story.StoryController>();
  int _currentIndex = 0;
  @override
  void dispose() {
    storyViewController.dispose();
    super.dispose();
  }

  void _handleDelete() {
    storyViewController.pause();

    DialogView.showDanger(
      context,
      "Are you sure to delete this story?",
      "Delete story",
          () async {
        Get.back();
        final currentStoryId = widget.stories[_currentIndex].id;

        if (currentStoryId != null) {
          bool success = await logicController.deleteStory(currentStoryId);

          if (success) {
            Get.back();
          } else {
            storyViewController.play();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<StoryItem> storyItems = widget.stories.map((StoryModel story) {
      bool isVideo =
          (story.fileUrl ?? "").toLowerCase().endsWith('.mp4') ||
              (story.fileUrl ?? "").toLowerCase().endsWith('.mov');

      if (isVideo) {
        return StoryItem.pageVideo(
          story.fileUrl!,
          controller: storyViewController,
        );
      } else {
        return StoryItem.pageImage(
          url: story.fileUrl!,
          controller: storyViewController,
          duration: const Duration(seconds: 5),
        );
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: storyViewController,
            onStoryShow: (StoryItem item, index) {
              int index = storyItems.indexOf(item);
              if (index != -1) {
                if (!mounted) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              }
            },
            onComplete: () {
              Get.back();
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Get.back();
              }
            },
          ),

          // هدر
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.userImage),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                    ),
                  ),
                  const Spacer(),
                  // دکمه حذف
                  Visibility(
                    visible: widget.isMe,
                    child: IconButton(
                      onPressed: _handleDelete,
                      icon: const Icon(
                        Icons.delete_outline, // آیکون کمی مدرن‌تر
                        color: Colors.white,
                        size: 28,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
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

