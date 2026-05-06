import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import '../../api_models_repo/models/notif_model.dart';
import '../chat_controller/notification_controller.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController controller = Get.put(NotificationController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.markNotificationsAsSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8), // رنگ پس‌زمینه ملایم‌تر
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xff00A98E)));
        }

        if (controller.notificationList.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: controller.notificationList.length,
            itemBuilder: (context, index) {
              return _NotificationItem(item: controller.notificationList[index]);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]
            ),
            child: Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
          ),
          const Gap(20),
          Text(
            "Notification empty",
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotifModel item;
  final NotificationController controller = Get.find();

  _NotificationItem({required this.item});

  @override
  Widget build(BuildContext context) {
    // تشخیص نوع
    // types: "Comment on Event", "Like on post", "New follower", "Comment on post", "New requested"

    IconData iconData;
    Color iconColor;
    String actionText;
    bool isRequest = false;

    String type = item.type ?? "";

    if (type.contains("Like")) {
      iconData = Icons.favorite_rounded;
      iconColor = Colors.redAccent;
      actionText = "Like your post";
    } else if (type.contains("Comment")) {
      iconData = Icons.comment_rounded;
      iconColor = Colors.blueAccent;
      actionText = "Send a comment";
    } else if (type == "New requested") {
      // --- نوع جدید: درخواست فالو ---
      iconData = Icons.person_add_rounded;
      iconColor = const Color(0xff00A98E);
      actionText = "Has requested follow to you";
      isRequest = true;
    } else if (type.contains("follower")) {
      iconData = Icons.person_rounded;
      iconColor = const Color(0xff00A98E);
      actionText = "followed you";
    } else {
      iconData = Icons.notifications_rounded;
      iconColor = Colors.orange;
      actionText = "New notification";
    }

    // تمیز کردن متن توضیحات
    String description = item.description ?? "";
    if (type.contains("Comment")) {
      final split = description.split("Comment:");
      if (split.length > 1) {
        description = split[1].replaceAll("'", "").trim();
      }
    } else {
      // برای بقیه موارد متن تکراری را حذف می‌کنیم تا UI تمیز شود
      description = "";
    }

    // زمان
    String timeAgo = "";
    if (item.date != null) {
      final diff = DateTime.now().difference(item.date!);
      if (diff.inMinutes < 60) {
        timeAgo = "${diff.inMinutes} minutes ago";
      } else if (diff.inHours < 24) {
        timeAgo = "${diff.inHours} hours ago";
      } else {
        timeAgo = "${diff.inDays} the other days";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: .rtl,
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // --- آواتار فرستنده ---
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade100, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: FastCachedImage(
                          url: item.profileModel?.image ?? "",
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Icon(iconData, size: 12, color: iconColor),
                      ),
                    ),
                  ],
                ),
                const Gap(12),

                // --- متن ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        textDirection: TextDirection.ltr,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: item.profileModel?.username ?? "User",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const TextSpan(text: " "),
                            TextSpan(text: actionText, style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const Gap(4),
                        Text(
                          description,
                          textDirection: TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                      const Gap(6),
                      Text(
                        timeAgo,
                        textDirection: .ltr,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- دکمه‌های تایید/رد برای New requested ---
            if (isRequest) ...[
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (item.id != null) controller.acceptFollowRequest(item.id!,item.profileModel?.email ?? "");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00A98E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // رد کردن (حذف اعلان)
                        if (item.id != null) controller.deleteNotification(item.id!);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Remove"),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class NotificationBadgeButton extends StatelessWidget {
  const NotificationBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());
    return GestureDetector(
      onTap: () {
        Get.toNamed("/notificationScreen");
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            size: 30,
            color: Colors.black87,
          ),
          // Badge
          Obx(() {
            if (controller.unseenCount.value == 0) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: -6,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    controller.unseenCount.value > 99
                        ? "+99"
                        : controller.unseenCount.value
                              .toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
