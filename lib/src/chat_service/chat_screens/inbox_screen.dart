import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';
import 'package:zenrun/core/widgets/Costance.dart';

import '../../../generated/assets.dart';
import '../chat_controller/chat_global_controller.dart';
import 'chat_screen.dart';
import 'create_group_screens.dart';

class InboxScreen extends StatelessWidget {
  final ChatGlobalController controller = Get.put(ChatGlobalController());

  // رنگ‌های مدرن‌تر
  final Color primaryColor = Color(0xff969bff);
  final Color secondaryColor = Color(0xffA78BFA); // برای گرادیانت
  final Color bgColor = const Color(0xffF5F7FA);

  InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.edit_note_rounded, color: primaryColor),
            onPressed: () => _showNewChatDialog(context),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingInbox.value) {
          return Center(
            child: Lottie.asset(Assets.animAnimLoading, height: 100),
          );
        }
        if (controller.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_chat_unread_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 20),
                Text(
                  "You have no message yet",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showNewChatDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Start a new conversation",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => controller.fetchInbox(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            itemCount: controller.conversations.length,
            itemBuilder: (ctx, index) {
              final chat = controller.conversations[index];
              return _buildConversationItem(chat);
            },
          ),
        );
      }),
    );
  }

  Widget _buildConversationItem(dynamic chat) {
    return Directionality(
      textDirection: .ltr,
      child: Container(
        decoration: BoxDecoration(
          color: chat.isPinned ? const Color(0xffF0FCF9) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: chat.isPinned
              ? Border.all(color: primaryColor.withOpacity(0.2))
              : Border(
                  bottom: BorderSide(
                    color: ColorsHelper.btn1.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Get.to(
                () => ChatScreen(
                  targetId: chat.isGroup ? chat.groupId! : chat.partnerId!,
                  isGroup: chat.isGroup,
                  name: chat.title,
                  avatarUrl: chat.avatarUrl,
                ),
              );
            },
            onLongPress: () => _showOptionsSheet(chat),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: chat.avatarUrl != null
                              ? FastCachedImage(
                                  url: chat.avatarUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.4),
                                        primaryColor.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      chat.title.isNotEmpty
                                          ? chat.title[0]
                                          : "?",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Online Indicator (Optional logic)
                      // if(chat.isOnline) Positioned(...)
                    ],
                  ),
                  const SizedBox(width: 15),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                chat.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.isPinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: primaryColor,
                                ),
                              ),
                            Text(
                              _formatDate(chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (chat.messageType != 'TEXT')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        chat.messageType == 'IMAGE'
                                            ? Icons.image_outlined
                                            : Icons.mic_none_outlined,
                                        size: 16,
                                        color: primaryColor,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      chat.messageType == 'TEXT'
                                          ? chat.lastMessage
                                          : (chat.messageType == 'IMAGE'
                                                ? "Image"
                                                : "Voice"),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: chat.unreadCount > 0
                                            ? Colors.black87
                                            : Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: chat.unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (chat.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "${chat.unreadCount}",
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return intl.DateFormat('HH:mm').format(date);
    }
    // اگر دیروز بود یا قدیمی‌تر، تاریخ بزن (می‌توانید از پکیج shamsi_date استفاده کنید)
    return intl.DateFormat('MM/dd').format(date);
  }

  void _showOptionsSheet(dynamic chat) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Directionality(
          textDirection: .ltr,
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
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  chat.isPinned ? "Remove the pin" : "Pin a conversation",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Get.back();
                  controller.pinConversation(
                    chat.isGroup ? chat.groupId! : chat.partnerId!,
                    chat.isGroup,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  "Delete conversation",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Get.back();
                  Get.defaultDialog(
                    title: "Delete conversation",
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                    middleText:
                        "Are you sure you want to delete this conversation?",
                    textConfirm: "Delete",
                    textCancel: "Back",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      Get.back();
                      controller.deleteConversation(
                        chat.isGroup ? chat.groupId! : chat.partnerId!,
                        chat.isGroup,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    Get.bottomSheet(
      Directionality(
        textDirection: .ltr,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ColorsHelper.btn1,
                  child: Icon(Icons.group_add, color: Colors.white),
                ),
                title: const Text(
                  "Create a new group",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Invite your friends to a group"),
                onTap: () {
                  Get.back();
                  Get.to(() => const SelectMembersScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
