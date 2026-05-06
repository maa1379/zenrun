import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenrun/src/api_models_repo/models/post_model.dart';
import 'package:zenrun/src/api_models_repo/models/profile_model.dart';

class NotifModel {
  final int? id;
  final String? senderEmail;
  final String? receiverEmail;
  bool? isRead;
  final DateTime? date;
  final String? description;
  final String? title;
  final String? type;
  final bool? isUsed;
  String? email;
  String? postId;
  PostModel? postModel;
  ProfileModel? profileModel;

  NotifModel({
    this.id,
    this.senderEmail,
    this.receiverEmail,
    this.isRead,
    this.date,
    this.description,
    this.title,
    this.type,
    this.isUsed,
  }) {
    if (description != null) {
      final result = extractEmailAndPostId(description ?? "");
      email = result['email'];
      postId = result['postId'];
    }
  }

  Map<String, String?> extractEmailAndPostId(String text) {
    final emailExp = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final emailMatch = emailExp.firstMatch(text);
    final email = emailMatch?.group(0);

    final postIdExp = RegExp(r'postId:(\d+)');
    final postIdMatch = postIdExp.firstMatch(text);
    final postId = postIdMatch?.group(1);

    return {'email': email, 'postId': postId};
  }

  factory NotifModel.fromJson(Map<String, dynamic> json) => NotifModel(
    id: json["id"],
    senderEmail: json["senderEmail"],
    receiverEmail: json["receiverEmail"],
    isRead: json["isRead"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    description: json["description"],
    title: json["title"],
    type: json["type"],
    isUsed: json["isUsed"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "senderEmail": senderEmail,
    "receiverEmail": receiverEmail,
    "isRead": isRead,
    "date": date?.toIso8601String(),
    "description": description,
    "title": title,
    "type": type,
    "isUsed": isUsed,
  };
}

class NotificationService {
  // ذخیره نوتیفیکیشن‌ها در کش
  Future<void> saveNotifications(List<NotifModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();

    // تبدیل نوتیفیکیشن‌ها به رشته‌های JSON
    List<String> notificationsJson = notifications.map((notification) => json.encode(notification.toJson())).toList();

    // ذخیره لیست رشته‌های JSON در کش
    await prefs.setStringList('notifications', notificationsJson);
  }

  // دریافت نوتیفیکیشن‌ها از کش
  Future<List<NotifModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationsJson = prefs.getStringList('notifications') ?? [];
    // تبدیل رشته‌های JSON به مدل‌های NotifModel
    return notificationsJson.map((jsonString) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return NotifModel.fromJson(jsonMap);
    }).toList();
  }

  // بررسی نوتیفیکیشن‌های جدید
  Future<int> getNewNotificationCount(List<NotifModel> allNotifications) async {
    List<NotifModel> savedNotifications = await getNotifications();
    return allNotifications.where((notification) => !savedNotifications.any((saved) => saved.id == notification.id && (saved.isRead ?? false))).length;
  }
}
