import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../../services/get_profile_service.dart';
import '../../api_models_repo/models/comment_model.dart';
import '../chat_controller/comment_controller.dart';

class PostCommentWidget extends StatelessWidget {
  final int postId;

  const PostCommentWidget({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final height = Get.height * 0.75;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // هندل بالای مودال
          const Gap(10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // هدر
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Comments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(height: 1),

          // لیست کامنت‌ها
          Expanded(
            child: GetBuilder<CommentController>(
              builder: (controller) {
                if (!controller.loading && controller.commentList.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A79B)));
                }

                if (controller.commentList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 50,
                          color: Colors.grey[300],
                        ),
                        const Gap(10),
                        Text(
                          "No comment has been registered yet",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // 🌟 ۱. جدا کردن کامنت‌های اصلی (آنهایی که ریپلای نیستند)
                List<CommentModel> rootComments = controller.commentList
                    .where((c) => c.replyId == 0 || c.replyId == null)
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rootComments.length,
                  separatorBuilder: (_, __) => const Gap(20),
                  itemBuilder: (context, index) {
                    final root = rootComments[index];
                    // 🌟 ۲. پیدا کردن ریپلای‌های مربوط به این کامنت (به صورت بازگشتی برای پیدا کردن همه زیرشاخه‌ها)
                    final children = _getThread(root.id!, controller.commentList);

                    return _CommentThreadWidget(
                      root: root,
                      children: children,
                      controller: controller,
                      postId: postId,
                    );
                  },
                );
              },
            ),
          ),

          // اینپوت نوشتن نظر
          _buildInputSection(context),
        ],
      ),
    );
  }

  // متد کمکی برای استخراج تمام ریپلای‌های زیرمجموعه یک کامنت اصلی
  List<CommentModel> _getThread(int rootId, List<CommentModel> allComments) {
    List<CommentModel> thread = [];
    void findChildren(int parentId) {
      var children = allComments.where((c) => c.replyId == parentId).toList();
      for (var child in children) {
        thread.add(child);
        findChildren(child.id!); // بررسی اینکه آیا خود این ریپلای هم ریپلای دارد یا نه
      }
    }
    findChildren(rootId);
    // مرتب‌سازی بر اساس تاریخ (قدیمی به جدید)
    thread.sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
    return thread;
  }

  Widget _buildInputSection(BuildContext context) {
    final controller = Get.find<CommentController>();
    final myProfile = Get.find<GetProfileService>().myProfile;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🌟 نوار وضعیت بالای کیبورد (برای نمایش حالت ویرایش یا پاسخ دادن)
          GetBuilder<CommentController>(
            builder: (ctrl) {
              if (ctrl.isEditing.value) {
                return _buildActionBanner("Editing comment...", Colors.blue, ctrl.cancelEditing);
              } else if (ctrl.isReplying.value && ctrl.replyingToComment != null) {
                return _buildActionBanner("Replying to ${ctrl.replyingToComment!.userName}...", Colors.grey[600]!, ctrl.cancelReplying);
              }
              return const SizedBox.shrink();
            },
          ),

          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: (myProfile?.image != null)
                    ? FastCachedImageProvider(myProfile!.image!)
                    : null,
              ),
              const Gap(10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: controller.commentText,
                    focusNode: controller.focusNode, // 🌟 اتصال کنترلر فوکوس
                    decoration: const InputDecoration(
                      hintText: "Write your comment...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              const Gap(8),

              GestureDetector(
                onTap: () async {
                  if (controller.commentText.text.trim().isEmpty) return;

                  if (controller.isEditing.value) {
                    await controller.editComment(
                      commentId: controller.editingCommentId!,
                      newText: controller.commentText.text,
                      postId: postId.toString(),
                      newRate: 0,
                    );
                  } else {
                    bool success = await controller.setComment(
                      postId: postId.toString(),
                    );
                    if (success) {
                      controller.getCommentList(postId: postId.toString());
                    }
                  }
                },
                child: GetBuilder<CommentController>(
                  builder: (ctrl) => Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ctrl.isEditing.value ? Colors.blue : const Color(0xFF00A79B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ctrl.isEditing.value ? Icons.check : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner(String text, Color color, VoidCallback onCancel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// 🌟 ویجت هوشمند برای مدیریت ریسه کامنت‌ها (Threads)
class _CommentThreadWidget extends StatefulWidget {
  final CommentModel root;
  final List<CommentModel> children;
  final CommentController controller;
  final int postId;

  const _CommentThreadWidget({
    required this.root,
    required this.children,
    required this.controller,
    required this.postId,
  });

  @override
  State<_CommentThreadWidget> createState() => _CommentThreadWidgetState();
}

class _CommentThreadWidgetState extends State<_CommentThreadWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // کامنت اصلی (پدر)
        _buildSingleComment(widget.root, isChild: false),

        // ریپلای‌ها (در صورت وجود)
        if (widget.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // دکمه باز کردن ریپلای‌ها (View X replies)
                if (!_isExpanded)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = true),
                    child: Row(
                      children: [
                        Container(width: 30, height: 1, color: Colors.grey[400]),
                        const Gap(10),
                        Text(
                          "View ${widget.children.length} more replies",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // نمایش ریپلای‌ها
                if (_isExpanded)
                  ...widget.children.map((child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSingleComment(child, isChild: true),
                  )),

                // دکمه بستن ریپلای‌ها
                if (_isExpanded)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = false),
                    child: Row(
                      children: [
                        Container(width: 30, height: 1, color: Colors.grey[400]),
                        const Gap(10),
                        Text(
                          "Hide replies",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // طراحی یک کامنت تکی (استفاده شده هم برای پدر و هم فرزند)
  Widget _buildSingleComment(CommentModel comment, {required bool isChild}) {
    bool isMe = widget.controller.isMyComment(comment);
    int cId = comment.id ?? 0;

    // مطمئن می‌شویم مپ‌های لایک برای این آیدی مقداردهی اولیه شده‌اند
    widget.controller.ensureLikeMapsInitialized(cId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // آواتار کوچک‌تر برای ریپلای‌ها
        CircleAvatar(
          radius: isChild ? 14 : 18,
          backgroundColor: Colors.grey[200],
          backgroundImage: (comment.userImage != null)
              ? FastCachedImageProvider(comment.userImage!)
              : null,
          child: (comment.userImage == null)
              ? Icon(Icons.person, color: Colors.grey, size: isChild ? 16 : 20)
              : null,
        ),
        const Gap(10),

        // بدنه اصلی کامنت (متن و نام)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.userName ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Gap(2),

              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    if (isChild && comment.replyTitle != null && comment.replyTitle != "0")
                      TextSpan(
                        text: "@${comment.replyTitle} ",
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    TextSpan(text: comment.comment1 ?? ""),
                  ],
                ),
              ),
              const Gap(6),

              Row(
                children: [
                  Text(
                    comment.date?.toString().substring(0, 10) ?? "",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const Gap(15),
                  GestureDetector(
                    onTap: () {
                      widget.controller.startReplying(comment);
                    },
                    child: const Text(
                      "Reply",
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Gap(10), // فاصله بین متن کامنت و دکمه لایک

        // 🌟 بخش لایک کامنت (قلب و تعداد)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              bool isLiked = widget.controller.isCommentLikedMap[cId]?.value ?? false;
              return GestureDetector(
                onTap: () => widget.controller.toggleCommentLike(cId),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isLiked ? Colors.red : Colors.grey[400],
                ),
              );
            }),
            Obx(() {
              int count = widget.controller.commentLikeCounts[cId]?.value ?? 0;
              if (count > 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    count.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),

        const Gap(5),

        // منوی حذف/ویرایش
        if (isMe)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') {
                widget.controller.startEditing(comment);
              } else if (value == 'delete') {
                widget.controller.deleteComment(
                  comment.id.toString(),
                  postId: widget.postId.toString(),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, size: 16), Gap(8), Text('Edit')]),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), Gap(8), Text('Delete', style: TextStyle(color: Colors.red))]),
              ),
            ],
          ),
      ],
    );
  }
}