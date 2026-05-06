import 'package:collection/collection.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/extetions.dart';
import 'package:zenrun/src/api_models_repo/models/comment_model.dart';
import 'package:zenrun/src/profile_pages/providers/comment_provider.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:zenrun/src/social_pages/providers/social_provider.dart';

import '../../../../core/widgets/Costance.dart';
import '../widgets/app_bar_widget.dart';

class CommentScreen extends StatefulWidget {
  const CommentScreen({
    super.key,
    required this.postId,
    required this.commentList,
  });

  final String postId;
  final List<CommentModel> commentList;

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {

  @override
  void initState() {
    super.initState();
    // دریافت کامنت‌ها هنگام ورود به صفحه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().getCommentList(context, widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        final social = context.read<SocialProvider>();
        final updatedComments = context.read<CommentProvider>().commentList;
        final post = [...social.posts, ...social.reels]
            .firstWhereOrNull((e) => e.id.toString() == widget.postId);
        post?.commentList?..clear()..addAll(updatedComments);
        social.update();
      },
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBarWidget().view(true, context),
            // فیلد کامنت پایین صفحه می‌چسبد
            bottomNavigationBar: _BuildCommentInput(postId: widget.postId),
            body: Consumer<CommentProvider>(
              builder: (context, provider, child) {
                if (provider.loading && provider.commentList.isEmpty) {
                  // فقط بار اول لودینگ نشان بده
                  return UiHelper.showLoading();
                }

                if (provider.commentList.isEmpty) {
                  return Center(child: Text("No comments yet.".toLn()));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.getCommentList(context, widget.postId);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    // لیست در پرووایدر معکوس شده، پس اینجا مستقیم نمایش میدهیم
                    itemCount: provider.commentList.length,
                    separatorBuilder: (c, i) => Divider(color: Colors.grey.shade200, height: 1),
                    itemBuilder: (context, index) {
                      final item = provider.commentList[index];
                      return _CommentItem(item: item, postId: widget.postId);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentModel item;
  final String postId;

  const _CommentItem({required this.item, required this.postId});

  @override
  Widget build(BuildContext context) {
    final myEmail = context.read<SocialProvider>().myEmail;
    final isMyComment = item.email == myEmail;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // آواتار
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (item.userImage != null && item.userImage!.isNotEmpty)
                ? FastCachedImageProvider(item.userImage!)
                : null,
            child: (item.userImage == null || item.userImage!.isEmpty)
                ? Icon(Icons.person, color: ColorsHelper.btn2, size: 20)
                : null,
          ),
          const Gap(10),

          // بدنه کامنت
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // نام کاربر
                    Expanded(
                      child: Text(
                        item.userName ?? item.email ?? "User",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // تاریخ و منو
                    Row(
                      children: [
                        Text(
                          item.date?.formatToText() ?? "", // از اکستنشن خودتان
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        if (isMyComment)
                          _buildOptionsMenu(context, item),
                      ],
                    )
                  ],
                ),
                const Gap(4),
                // متن کامنت
                Text(
                  item.comment1 ?? "",
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context, CommentModel item) {
    return GestureDetector(
      onTapDown: (details) {
        final offset = details.globalPosition;
        showMenu(
          position: RelativeRect.fromLTRB(
            offset.dx, offset.dy,
            MediaQuery.of(context).size.width - offset.dx,
            MediaQuery.of(context).size.height - offset.dy,
          ),
          context: context,
          color: Colors.white,
          shape: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: ColorsHelper.btn2, width: 1),
          ),
          items: [
            PopupMenuItem(
              height: 35,
              child: const Text("Edit", style: TextStyle(fontSize: 13)),
              onTap: () {
                final provider = context.read<CommentProvider>();
                provider.comment.text = item.comment1 ?? "";
                provider.commentModel = item;
                FocusScope.of(context).requestFocus(provider.focusNode);
              },
            ),
            PopupMenuItem(
              height: 35,
              child: const Text("Delete", style: TextStyle(fontSize: 13, color: Colors.red)),
              onTap: () {
                // استفاده از متد جدید Optimistic
                context.read<CommentProvider>().deleteCommentOptimistic(
                    context,
                    item.id.toString(),
                    postId
                );
              },
            ),
          ],
        );
      },
      child: const Padding(
        padding: EdgeInsets.only(left: 8.0, right: 0),
        child: Icon(Icons.more_horiz, size: 20, color: Colors.grey),
      ),
    );
  }
}

class _BuildCommentInput extends StatelessWidget {
  final String postId;
  const _BuildCommentInput({required this.postId});

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileProvider>().profile;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (profile?.image?.isNotEmpty ?? false)
                  ? FastCachedImageProvider(profile!.image!)
                  : null,
              child: (profile?.image == null || profile!.image!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const Gap(10),
            Expanded(
              child: Consumer<CommentProvider>(
                builder: (context, provider, _) {
                  return TextField(
                    controller: provider.comment,
                    focusNode: provider.focusNode,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: provider.commentModel == null
                          ? "Add a comment..."
                          : "Editing comment...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                            provider.commentModel == null ? Icons.send : Icons.check,
                            color: ColorsHelper.btn1
                        ),
                        onPressed: () {
                          // استفاده از متد جدید Optimistic
                          provider.sendCommentOptimistic(
                            context,
                            postId,
                            profile?.family ?? "",
                            profile?.name ?? "",
                            profile?.image ?? "",
                          );
                        },
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
  }
}