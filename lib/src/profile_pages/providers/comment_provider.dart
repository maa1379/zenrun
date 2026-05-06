import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/comment_model.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';

class CommentProvider extends ChangeNotifier {
  bool loading = false;
  List<CommentModel> commentList = [];
  TextEditingController comment = TextEditingController();
  final FocusNode focusNode = FocusNode();
  CommentModel? commentModel;

  void update() => notifyListeners();

  String _getCacheKey(String postId) => 'cached_comments_$postId';

  Future<List<CommentModel>> getCommentList(
      BuildContext context,
      String postId, {
        bool onPage = false,
        bool useCache = true, // پارامتر جدید برای کنترل کش
      }) async {
    if (onPage) {
      loading = false;
      update();
    }

    // 1. Load from Cache & Show Immediately
    if (useCache) {
      await _loadFromCache(postId);
      if (commentList.isNotEmpty) {
        loading = true;
        update(); // نمایش دیتای کش
      }
    }

    // 2. Fetch from API
    final res = await ApiService.instance.getCommentListApi(postId);
    if (res is DataSuccess) {
      commentList.clear();
      commentList.addAll(res.data ?? []);

      // 3. Save Fresh Data to Cache
      if (useCache) {
        _saveToCache(postId);
      }

      loading = true;
      update();
      return res.data ?? [];
    } else {
      // اگر ارور خوردیم و کش هم خالی بود، دیالوگ نشان بده
      if (commentList.isEmpty && context.mounted) {
        ViewHelper.showErrorDialog(context);
      }
      return [];
    }
  }

  Future<void> _loadFromCache(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_getCacheKey(postId));
      if (json != null) {
        final List decoded = jsonDecode(json);
        commentList = decoded.map((e) => CommentModel.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(commentList.map((e) => e.toJson()).toList());
      await prefs.setString(_getCacheKey(postId), json);
    } catch (_) {}
  }

  // ارسال کامنت به روش Optimistic (آنی)
  Future<void> sendCommentOptimistic(
    BuildContext context,
    String postId,
    String userFamily,
    String userName,
    String userImage,
  ) async {
    final textToSend = comment.text.trim();
    if (textToSend.isEmpty) return;

    // ۱. ساخت یک مدل موقت و افزودن به ابتدای لیست
    final tempId = DateTime.now().millisecondsSinceEpoch; // آی‌دی موقت
    final tempComment = CommentModel(
      id: tempId,
      // موقتا int یا string
      postId: int.tryParse(postId),
      comment1: textToSend,
      userName: userName,
      // یا ترکیب نام و فامیلی
      userImage: userImage,
      email: await PrefHelpers.getUser(),
      // ایمیل خود یوزر
      date: DateTime.now(),
    );

    // افزودن به ابتدای لیست (چون لیست را معکوس نگه می‌داریم)
    commentList.insert(0, tempComment);
    comment.clear(); // پاک کردن ورودی بلافاصله
    notifyListeners(); // آپدیت UI

    // ۲. ارسال واقعی به سرور در پس‌زمینه
    // نکته: اگر حالت ویرایش (Edit) باشد:
    if (commentModel != null) {
      // لاجیک ادیت جداگانه است، اینجا برای ارسال جدید:
      await _handleEdit(context, postId, userFamily, userName, userImage);
      return;
    }

    // ارسال جدید
    final res = await ApiService.instance.setCommentApi(
      id: "0",
      // برای کامنت جدید معمولا 0 یا نال می‌فرستند
      postId: postId,
      comment: textToSend,
      userFamily: userFamily,
      userName: userName,
      userImage: userImage,
    );

    // ۳. مدیریت نتیجه سرور
    if (res is DataSuccess) {
      // موفقیت: معمولاً سرور لیست جدید یا کامنت ثبت شده را برمی‌گرداند.
      // برای اطمینان و هماهنگی آی‌دی‌ها، یک بار لیست را بیصدا رفرش می‌کنیم
      getCommentList(context, postId);
    } else {
      // شکست: کامنت موقت را حذف کن و به کاربر خبر بده
      commentList.removeWhere((element) => element.id == tempId);
      comment.text = textToSend; // متن را برگردان تا کاربر دوباره تلاش کند
      notifyListeners();
      if (context.mounted) ViewHelper.showErrorDialog(context);
    }
  }

  Future<void> _handleEdit(
    BuildContext context,
    String postId,
    String f,
    String n,
    String i,
  ) async {
    // پیاده سازی مشابه برای ادیت...
    // فعلا برای سادگی همان روش قدیمی را برای ادیت نگه می‌داریم یا
    // می‌توانید آن را هم Optimistic کنید.
    final idToEdit = commentModel!.id.toString();
    String text = comment.text;

    // آپدیت لوکال
    final index = commentList.indexWhere(
      (element) => element.id == commentModel!.id,
    );
    if (index != -1) {
      commentList[index].comment1 = text;
      notifyListeners();
    }
    comment.clear();
    commentModel = null;
    FocusManager.instance.primaryFocus?.unfocus();

    await ApiService.instance.setCommentApi(
      id: idToEdit,
      postId: postId,
      comment: text,
      userFamily: f,
      userName: n,
      userImage: i,
    );
    // رفرش نهایی برای اطمینان
    getCommentList(context, postId);
  }

  // حذف کامنت به روش Optimistic
  Future<void> deleteCommentOptimistic(
    BuildContext context,
    String id,
    String postId,
  ) async {
    // ۱. حذف از لیست لوکال
    final int indexBackup = commentList.indexWhere(
      (element) => element.id.toString() == id,
    );
    CommentModel? backupItem;

    if (indexBackup != -1) {
      backupItem = commentList[indexBackup];
      commentList.removeAt(indexBackup);
      notifyListeners();
    }

    // ۲. درخواست حذف به سرور
    final res = await ApiService.instance.deleteCommentApi(id);

    if (res is DataSuccess) {
      // موفقیت: کار خاصی لازم نیست چون قبلا حذف کردیم
    } else {
      // شکست: آیتم را برگردان
      if (backupItem != null) {
        commentList.insert(indexBackup, backupItem);
        notifyListeners();
        if (context.mounted) ViewHelper.showErrorDialog(context);
      }
    }
  }
}
