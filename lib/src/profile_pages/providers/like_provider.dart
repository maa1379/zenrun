import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenrun/src/api_models_repo/models/like_model.dart';

import '../../../core/network/DataState.dart';
import '../../../core/widgets/Costance.dart';
import '../../api_models_repo/api_service.dart';

class LikeProvider extends ChangeNotifier {
  bool loading = false;
  void update() => notifyListeners();
  String _getCacheKey(String postId) => 'cached_likes_$postId';
  List<LikeModel> likeList = [];

  Future<List<LikeModel>> getLikeList(String postId, {bool useCache = true}) async {

    // 1. Load Cache
    if (useCache) {
      await _loadFromCache(postId);
      // اگر کش دیتا داشت، می‌توانیم همینجا ناتیفای کنیم یا لیست را برگردانیم
      if (likeList.isNotEmpty) {
        notifyListeners();
      }
    }

    // 2. Fetch API
    final res = await ApiService.instance.getLikeListApi(postId);

    if (res is DataSuccess) {
      final freshList = res.data ?? [];
      likeList = freshList; // آپدیت لیست داخلی

      // 3. Save Cache
      if (useCache) {
        _saveToCache(postId);
      }

      notifyListeners();
      return freshList;
    } else {
      // در صورت خطا، اگر کش داشتیم همان را برمی‌گردانیم تا UI خالی نشود
      return likeList;
    }
  }

  Future<void> _loadFromCache(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_getCacheKey(postId));
      if (json != null) {
        final List decoded = jsonDecode(json);
        likeList = decoded.map((e) => LikeModel.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(likeList.map((e) => e.toJson()).toList());
      await prefs.setString(_getCacheKey(postId), json);
    } catch (_) {}
  }

  Future<bool> setLike(BuildContext context, String postId) async {
    final res = await ApiService.instance.setLikeApi(postId);
    if (res is DataSuccess) {
      _saveToCache(postId);
      return true;
    } else if (res is DataFailed) {
      return false;
    } else {
      ViewHelper.showErrorDialog(context);
      return false;
    }
  }

  Future<bool> deleteLike(BuildContext context, String id) async {
    final res = await ApiService.instance.deleteLikeApi(id);
    if (res is DataSuccess) {
      return false;
    } else if (res is DataFailed) {
      return true;
    } else {
      ViewHelper.showErrorDialog(context);
      return true;
    }
  }
}
