import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:zenrun/src/chat_service/chat_controller/social_controller.dart';
import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../services/get_profile_service.dart';
import '../flush_helper.dart';
import './api_helper.dart';
import '../../../core/widgets/extetions.dart';
import '../../api_models_repo/models/comment_model.dart';

class CommentController extends GetxController {
  List<CommentModel> commentList = [];
  bool loading = false;

  TextEditingController commentText = TextEditingController();
  FocusNode focusNode = FocusNode(); // 🌟 کنترل کیبورد برای ریپلای

  var commentLikeCounts = <int, RxInt>{}.obs;
  var isCommentLikedMap = <int, RxBool>{}.obs;
  var commentUserLikeIds = <int, int?>{}.obs;
  var isProcessingCommentLike = <int, bool>{}.obs;

  void ensureLikeMapsInitialized(int commentId) {
    if (!commentLikeCounts.containsKey(commentId)) commentLikeCounts[commentId] = 0.obs;
    if (!isCommentLikedMap.containsKey(commentId)) isCommentLikedMap[commentId] = false.obs;
    if (!commentUserLikeIds.containsKey(commentId)) commentUserLikeIds[commentId] = null;
    if (!isProcessingCommentLike.containsKey(commentId)) isProcessingCommentLike[commentId] = false;
  }

  Future<void> fetchCommentLikes(int commentId) async {
    ensureLikeMapsInitialized(commentId);
    final res = await ApiHelper.post("Like.aspx", queryParams: {"commentId": commentId.toString()});

    if (res.isSuccess) {
      String? userPhone = await PrefHelpers.getUser();
      final likesList = (res.data as List);

      commentLikeCounts[commentId]!.value = likesList.length;
      var myLike = likesList.firstWhereOrNull((e) => e['Email'] == userPhone);

      if (myLike != null) {
        isCommentLikedMap[commentId]!.value = true;
        commentUserLikeIds[commentId] = myLike['id'];
      } else {
        isCommentLikedMap[commentId]!.value = false;
        commentUserLikeIds[commentId] = null;
      }
    }
  }

  // تغییر وضعیت لایک کامنت
  Future<void> toggleCommentLike(int commentId) async {
    if (isProcessingCommentLike[commentId] == true) return;

    ensureLikeMapsInitialized(commentId);
    isProcessingCommentLike[commentId] = true;

    bool isCurrentlyLiked = isCommentLikedMap[commentId]!.value;
    int? likeId = commentUserLikeIds[commentId];

    // ۱. آپدیت خوش‌بینانه UI (بلافاصله قلب قرمز شود)
    isCommentLikedMap[commentId]!.value = !isCurrentlyLiked;
    commentLikeCounts[commentId]!.value += isCommentLikedMap[commentId]!.value ? 1 : -1;

    try {
      if (isCurrentlyLiked) {
        // حذف لایک
        if (likeId != null) {
          final res = await ApiHelper.post(
            "DeleteLike.aspx",
            queryParams: {"id": likeId.toString()},
          );
          if (!res.isSuccess) {
            _revertLikeState(commentId, isCurrentlyLiked);
          } else {
            commentUserLikeIds[commentId] = null;
          }
        }
      } else {
        // ثبت لایک جدید (ارسال postId صفر و ارسال commentId)
        final res = await ApiHelper.post(
          "SetLike.aspx",
          queryParams: {
            "Email": await PrefHelpers.getUser(),
            "postId": "0",
            "commentId": commentId.toString()
          },
        );

        if (res.isSuccess) {
          await _syncLikeIdOnly(commentId);
        } else {
          _revertLikeState(commentId, isCurrentlyLiked);
        }
      }
    } catch (e) {
      _revertLikeState(commentId, isCurrentlyLiked);
    } finally {
      isProcessingCommentLike[commentId] = false;
    }
  }

  Future<void> _syncLikeIdOnly(int commentId) async {
    final likeRes = await ApiHelper.post(
      "Like.aspx",
      queryParams: {"commentId": commentId.toString()},
    );
    if (likeRes.isSuccess) {
      String? userPhone = await PrefHelpers.getUser();
      final likesList = (likeRes.data as List);
      var myLike = likesList.firstWhereOrNull((e) => e['Email'] == userPhone);
      if (myLike != null) {
        commentUserLikeIds[commentId] = myLike['id'];
      }
    }
  }

  void _revertLikeState(int commentId, bool previousState) {
    isCommentLikedMap[commentId]!.value = previousState;
    commentLikeCounts[commentId]!.value += previousState ? 1 : -1;
  }

  var isEditing = false.obs;
  String? editingCommentId;

  // 🌟 متغیرهای مدیریت ریپلای
  var isReplying = false.obs;
  CommentModel? replyingToComment;

  void startEditing(CommentModel comment) {
    cancelReplying(); // اگر در حال ریپلای بود، لغوش کن
    commentText.text = comment.comment1 ?? "";
    editingCommentId = comment.id.toString();
    isEditing.value = true;
    update();
    focusNode.requestFocus(); // باز شدن خودکار کیبورد
  }

  void cancelEditing() {
    commentText.clear();
    editingCommentId = null;
    isEditing.value = false;
    update();
    focusNode.unfocus();
  }

  // 🌟 متدهای جدید برای شروع و لغو ریپلای
  void startReplying(CommentModel comment) {
    cancelEditing(); // اگر در حال ویرایش بود، لغوش کن
    replyingToComment = comment;
    isReplying.value = true;
    commentText.clear();
    update();
    focusNode.requestFocus(); // باز شدن کیبورد بلافاصله بعد از زدن دکمه Reply
  }

  void cancelReplying() {
    replyingToComment = null;
    isReplying.value = false;
    commentText.clear();
    update();
    focusNode.unfocus();
  }

  Future<void> getCommentList({String? postId, String? eventId}) async {
    loading = false;
    update();
    final res = await ApiHelper.post(
      "Comment.aspx",
      queryParams: {
        if (postId != null) "postId": postId,
      },
    );
    if (res.isSuccess) {
      commentList.clear();
      commentList.addAll((res.data as List).toListModel(CommentModel.fromJson));
      loading = true;
      update();
      for (var comment in commentList) {
        if (comment.id != null) {
          fetchCommentLikes(comment.id!);
        }
      }
    }
  }

  bool isMyComment(CommentModel item) {
    return item.email == Get.find<GetProfileService>().myProfile?.email;
  }

  Future<bool> setComment({
    String? postId,
    String? commentId,
  }) async {
    final res = await ApiHelper.post(
      "SetComment.aspx",
      disableLoading: false,
      queryParams: {
        "id": commentId ?? "0",
        // 🌟 ارسال مقادیر داینامیک ریپلای به سمت سرور
        "replyId": isReplying.value ? (replyingToComment?.id?.toString() ?? "0") : "0",
        "replyTitle": isReplying.value ? (replyingToComment?.userName ?? "0") : "0",
        "Email": await PrefHelpers.getUser(),
        "date": DateTime.now().toIso8601String(),
        "postId": postId,
        "comment": commentText.text,
        "userFamily": Get.find<GetProfileService>().myProfile?.family,
        "userImage": Get.find<GetProfileService>().myProfile?.image,
        "userName":
        Get.find<GetProfileService>().myProfile?.username ??
            Get.find<GetProfileService>().myProfile?.email,
      },
    );
    if (res.isSuccess) {
      if (postId != null) {
        if (Get.isRegistered<SocialController>()) {
          Get.find<SocialController>().changeCommentCount(int.parse(postId), 1);
        }
      }
      cancelReplying(); // پاک کردن وضعیت ریپلای بعد از ارسال موفق
      return true;
    } else {
      return false;
    }
  }

  Future<bool> deleteComment(String commentId, {String? postId}) async {
    final res = await ApiHelper.post(
      "DeleteComment.aspx",
      queryParams: {"id": commentId},
      disableLoading: false,
    );

    if (res.isSuccess) {
      if (postId != null && Get.isRegistered<SocialController>()) {
        Get.find<SocialController>().changeCommentCount(int.parse(postId), -1);
      }
      commentList.removeWhere((element) => element.id.toString() == commentId);
      update();
      FlushHelper.success("کامنت با موفقیت حذف شد");
      return true;
    } else {
      FlushHelper.error("حذف کامنت انجام نشد");
      return false;
    }
  }

  Future<bool> editComment({
    required String commentId,
    required String newText,
    required double newRate,
    String? postId,
  }) async {
    final res = await ApiHelper.post(
      "SetComment.aspx",
      disableLoading: false,
      queryParams: {
        "comment": commentText.text,
        "date": DateTime.now().toIso8601String(),
        // در ویرایش، وضعیت ریپلای تغییری نمیکند اما برای اطمینان مقادیر پیش‌فرض میدهیم
        "replyId": "0",
        "replyTitle": "0",
        "id": commentId,
        "phone": await PrefHelpers.getUser(),
        "postId": postId ?? "0",
        "userImage": Get.find<GetProfileService>().myProfile?.image,
        "userName":
        Get.find<GetProfileService>().myProfile?.username ??
            Get.find<GetProfileService>().myProfile?.phone,
      },
    );

    if (res.isSuccess) {
      int index = commentList.indexWhere(
            (element) => element.id.toString() == commentId,
      );
      if (index != -1) {
        commentList[index].comment1 = newText;
        update();
      }
      cancelEditing();
      FlushHelper.success("کامنت با موفقیت ویرایش شد");
      return true;
    } else {
      FlushHelper.error("ویرایش کامنت انجام نشد");
      return false;
    }
  }
}