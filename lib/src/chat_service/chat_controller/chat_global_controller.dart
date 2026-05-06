import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/src/chat_service/message_model.dart';

import '../../../services/socket_service.dart';
import 'call_controller.dart';

class ChatGlobalController extends GetxController {
  // آدرس سرور: در اندروید امولاتور حتما باید 10.0.2.2 باشد (نه localhost)
  static const String baseUrl = "http://217.182.171.221/chat";

  late final SocketService socketService;

  String? _token;
  String? get token => _token;

  int? currentUserId;
  var conversations = <ConversationModel>[].obs;
  var allUsers = <ChatUser>[].obs;
  var isLoadingInbox = false.obs;

  @override
  void onInit() {
    super.onInit();
    loginWithPhone();
    socketService = Get.find<SocketService>();
    ever(
      socketService.newMessageReceived,
      (msg) => _handleNewMessageForInbox(msg),
    );
    // گوش دادن به پیام‌های جدید برای آپدیت لیست اینباکس
    if (socketService.socket != null && socketService.socket!.connected) {
      _setupSocketListeners();
    }
    // try {
    // } catch (e) {
    //   print("SocketService Init Error: $e");
    // }
  }

  void _handleNewMessageForInbox(MessageModel? msg) {
    if (msg == null) return;

    // تشخیص آیدی طرف مقابل در اینباکس
    int? chatPartnerId;
    bool isGroupMsg = msg.groupId != null;

    if (isGroupMsg) {
      chatPartnerId = msg.groupId;
    } else {
      // اگر من فرستادم، طرف مقابل receiver است. اگر او فرستاده، طرف مقابل sender است.
      chatPartnerId = (msg.senderId == currentUserId)
          ? msg.receiverId
          : msg.senderId;
    }

    // پیدا کردن آیتم در لیست فعلی
    int index = conversations.indexWhere(
      (c) =>
          (isGroupMsg && c.isGroup && c.groupId == chatPartnerId) ||
          (!isGroupMsg && !c.isGroup && c.partnerId == chatPartnerId),
    );

    if (index != -1) {
      // --- گفتگو وجود دارد: آپدیتش کن ---
      var chat = conversations[index];

      // 1. آپدیت متن و زمان
      chat.lastMessage = (msg.type == 'TEXT')
          ? msg.content
          : (msg.type == 'IMAGE' ? "تصویر" : "فایل");
      chat.lastMessageTime = msg.createdAt;
      chat.messageType = msg.type;

      // 2. آپدیت کانتر (فقط اگر پیام ورودی باشد)
      if (msg.senderId != currentUserId) {
        chat.unreadCount += 1;
      }

      // 3. آوردن به بالای لیست
      conversations.removeAt(index);
      conversations.insert(0, chat);
      conversations.refresh(); // برای آپدیت UI
    } else {
      fetchInbox();
    }
  }

  void resetUnreadCount(int targetId, bool isGroup) {
    int index = conversations.indexWhere(
      (c) =>
          (isGroup && c.isGroup && c.groupId == targetId) ||
          (!isGroup && !c.isGroup && c.partnerId == targetId),
    );

    if (index != -1) {
      var chat = conversations[index];
      chat.unreadCount = 0;
      conversations[index] = chat;
      conversations.refresh();
    }
  }

  // --- هدرهای درخواست HTTP ---
  Map<String, String> get headers {
    var headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (_token != null) {
      headers["Authorization"] = "Bearer $_token";
    }
    return headers;
  }

  // --- 1. لاگین و اتصال به سوکت ---
  Future<bool> loginWithPhone() async {
    try {
      final phone = await PrefHelpers.getUser();
      final fcm = await PrefHelpers.getFcm();
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "fcmToken": fcm}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String?;
        if (_token == null) return false;

        if (data['user'] != null) {
          currentUserId = data['user']['id'];
        }

        socketService.connect(_token!);
        _setupSocketListeners();
        fetchInbox();
        return true;
      }

      debugPrint("Login Failed: Status ${response.statusCode}");
      return false;
    } catch (e) {
      debugPrint("Login Exception: $e");
      return false;
    }
  }

  void _setupSocketListeners() {
    if (socketService.socket == null) return;

    // پاک کردن لیسنر قبلی
    socketService.socket!.off("incoming_call");

    print("Listening for incoming calls...");

    socketService.socket!.on("incoming_call", (data) {
      print("Incoming Call: $data");

      // نکته مهم: اگر قبلا کنترلر در حافظه مانده، پاکش کن تا State ریست شود
      if (Get.isRegistered<CallController>()) {
        Get.delete<CallController>(force: true);
      }

      // ساخت کنترلر جدید
      final callController = Get.put(CallController());
      callController.handleIncomingCall(data);
    });
  }

  void markChatAsRead(int targetId, bool isGroup) {
    // پیدا کردن ایندکس گفتگو در لیست
    final index = conversations.indexWhere(
      (c) =>
          (isGroup && c.isGroup && c.groupId == targetId) ||
          (!isGroup && !c.isGroup && c.partnerId == targetId),
    );

    if (index != -1) {
      var chat = conversations[index];

      // اگر تعداد بیشتر از 0 بود، صفرش کن و لیست را رفرش کن
      if (chat.unreadCount > 0) {
        chat.unreadCount = 0;
        conversations[index] = chat;
        conversations.refresh(); // مهم برای آپدیت UI
      }
    }
  }

  // --- دریافت اینباکس ---
  void fetchInbox() async {
    if (_token == null) await loginWithPhone();
    if (_token == null) return;

    isLoadingInbox.value = true;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/getInbox"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        conversations.assignAll(
          data.map((e) => ConversationModel.fromJson(e)).toList(),
        );
      }
    } catch (e) {
      print("Inbox Error: $e");
    } finally {
      isLoadingInbox.value = false;
    }
  }

  Future<void> pinConversation(int targetId, bool isGroup) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/conversations/pin"),
        headers: headers,
        body: jsonEncode({"targetId": targetId, "isGroup": isGroup}),
      );
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        fetchInbox(); // رفرش لیست برای تغییر ترتیب
      }
    } catch (e) {
      Get.snackbar("خطا", "عملیات ناموفق بود");
    }
  }

  // 2. حذف چت (Clear History)
  Future<void> deleteConversation(int targetId, bool isGroup) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/conversations/$targetId?isGroup=$isGroup"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        fetchInbox(); // رفرش لیست
        Get.snackbar("موفق", "تاریخچه چت پاک شد");
      }
    } catch (e) {
      Get.snackbar("خطا", "حذف چت ناموفق بود");
    }
  }

  Future<bool> deleteMessageForEveryone(int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/deleteMessage/$messageId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Message Error: $e");
      return false;
    }
  }

  // --- دریافت تاریخچه چت ---
  Future<List<MessageModel>> getChatHistory(
    int targetId, {
    bool isGroup = false,
  }) async {
    if (_token == null) return [];

    try {
      final uri = Uri.parse("$baseUrl/getChatHistory").replace(
        queryParameters: {
          "targetId": targetId.toString(),
          "isGroup": isGroup.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => MessageModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Get History Error: $e");
      return [];
    }
  }

  // --- آپلود فایل (با http و Progress) ---
  Future<String?> uploadFile(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    if (_token == null) return null;

    try {
      final url = Uri.parse("http://217.182.171.221/api/upload");

      final request = MultipartRequestWithProgress(
        "POST",
        url,
        onProgress: (bytes, total) {
          if (onProgress != null) {
            onProgress(bytes / total);
          }
        },
      );

      request.headers.addAll(headers);
      request.headers.remove("Content-Type"); // توسط MultipartRequest ست می‌شود

      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();
      MediaType mediaType;
      if (['mp4', 'mov', 'mkv', 'avi'].contains(extension)) {
        // برای ویدیوها
        mediaType = MediaType(
          'video',
          extension == 'mov' ? 'quicktime' : extension,
        );
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        // برای عکس‌ها
        mediaType = MediaType('image', extension == 'jpg' ? 'jpeg' : extension);
      } else if (['m4a', 'mp3', 'ogg', 'wav', 'aac'].contains(extension)) {
        // برای ویس‌ها (m4a معمولاً به عنوان audio/mp4 شناخته می‌شود)
        mediaType = MediaType('audio', extension == 'm4a' ? 'mp4' : extension);
      } else {
        // حالت پیش‌فرض برای فایل‌های ناشناخته
        mediaType = MediaType('application', 'octet-stream');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      print("Upload Failed: ${response.body}");
      return null;
    } catch (e) {
      print("Upload Exception: $e");
      return null;
    }
  }

  // --- مدیریت گروه و کاربران ---
  Future<void> fetchAllUsers() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        allUsers.assignAll(data.map((e) => ChatUser.fromJson(e)).toList());
      }
    } catch (e) {
      print("Fetch Users Error: $e");
    }
  }

  Future<bool> createGroup(
    String name,
    String? description,
    File? imageFile,
    List<int> memberIds,
  ) async {
    try {
      String? avatarUrl;
      if (imageFile != null) {
        avatarUrl = await uploadFile(imageFile);
      }

      final body = {
        "name": name,
        "description": description,
        "avatarUrl": avatarUrl,
        "initialMembers": memberIds,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/groups"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        fetchInbox();
        return true;
      }
      return false;
    } catch (e) {
      print("Create Group Error: $e");
      return false;
    }
  }

  Future<int?> syncUserWithChatBackend(String username) async {
    if (_token == null) await loginWithPhone();
    if (_token == null) return null;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/syncUser"),
        headers: headers,
        body: jsonEncode({
          "username": username,
        }), // تغییر نام فیلد به username طبق بک‌اند
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users/$userId/details"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> addGroupMember(int groupId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/groups/$groupId/members"),
        headers: headers,
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        Get.snackbar("خطا", "افزودن کاربر انجام نشد");
        return false;
      }
    } catch (e) {
      print("Add Member Error: $e");
      return false;
    }
  }

  // --- حذف (کیک کردن) عضو از گروه ---
  Future<bool> kickGroupMember(int groupId, int userId) async {
    try {
      // متد DELETE معمولا بادی دارد، اما در برخی پیاده‌سازی‌ها باید دقت کرد
      final request = http.Request(
        'DELETE',
        Uri.parse("$baseUrl/groups/$groupId/members"),
      );
      request.headers.addAll(headers);
      request.body = jsonEncode({"userId": userId});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Kick Error: ${response.body}");
        Get.snackbar("خطا", "حذف کاربر انجام نشد (شاید ادمین نیستید)");
        return false;
      }
    } catch (e) {
      print("Kick Exception: $e");
      return false;
    }
  }

  Future<bool> blockUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/block"),
        headers: headers,
        body: jsonEncode({"blockedId": userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- آنبلاک کردن ---
  Future<bool> unblockUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/unblock"),
        headers: headers,
        body: jsonEncode({"blockedId": userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// کلاس کمکی برای پروگرس بار در http
class MultipartRequestWithProgress extends http.MultipartRequest {
  final Function(int bytes, int totalBytes) onProgress;

  MultipartRequestWithProgress(
    String method,
    Uri url, {
    required this.onProgress,
  }) : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}
