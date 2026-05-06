import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:video_player/video_player.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/chat_service/message_model.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../generated/assets.dart';
import '../../../services/socket_service.dart';
import '../chat_controller/call_controller.dart';
import '../chat_controller/chat_global_controller.dart';

class ChatScreenController extends GetxController {
  final int targetId;
  final bool isGroup;

  ChatScreenController({required this.targetId, required this.isGroup});

  var isEditing = false.obs;
  var editingMessageId = RxnInt();
  late final ChatGlobalController globalController;
  late final SocketService socketService;
  var showEmojiPicker = false.obs;
  final FocusNode focusNode = FocusNode();
  final TextEditingController textCtrl = TextEditingController();
  var groupMembers = <ChatUser>[].obs; // لیست اعضا
  var onlineCount = 0.obs;
  late final RecorderController recorderController;

  var messages = <MessageModel>[].obs;
  var isTyping = false.obs;

  // --- Recording States ---
  var isRecording = false.obs;
  var isRecordingLocked = false.obs;
  var recordDuration = 0.obs;
  Timer? _recordTimer;
  var isBlocked = false.obs;
  var isOnline = false.obs;
  var userFullName = "".obs;
  var userUsername = "".obs;
  var userBio = "".obs;
  var userAvatar = RxnString();
  var isReviewing = false.obs; // آیا ضبط تمام شده و در حال بازبینی است؟
  String? recordedFilePath;

  var showSendButton = false.obs;
  var replyMessage = Rxn<MessageModel>();
  var uploadingFiles = <String, double>{}.obs;

  Worker? _msgWorker;
  Worker? _typingWorker;
  Worker? _pinWorker;

  Timer? _debounce;

  final AutoScrollController scrollCtrl = AutoScrollController(
    viewportBoundaryGetter: () =>
        Rect.fromLTRB(0, 0, 0, MediaQuery
            .of(Get.context!)
            .padding
            .bottom), axis: Axis.vertical,);

  Future<void> scrollToMessage(int targetMessageId) async {
    int index = messages.indexWhere((msg) => msg.id == targetMessageId);
    if (index != -1) {
      await scrollCtrl.scrollToIndex(index,
        preferPosition: AutoScrollPosition.begin, // تغییر به begin یا middle
      );
      // یک افکت فلش زدن برای جلب توجه (اختیاری)
      // highlightMessage(index);
    } else {
      Get.snackbar("پیام قدیمی", "این پیام در لیست فعلی بارگذاری نشده است.");
    }
  }

  late final PlayerController reviewPlayerController;

  @override
  void onInit() {
    super.onInit();
    try {
      globalController = Get.find<ChatGlobalController>();
      socketService = Get.find<SocketService>();

      recorderController = RecorderController();
      reviewPlayerController = PlayerController();

      // صفر کردن کانتر هنگام ورود
      globalController.markChatAsRead(targetId, isGroup);

      _ensureConnection();
      loadMessages();

      // فراخوانی لیسنرها
      listenToSocket();
      listenToNewSocketEvents();

      if (isGroup) {
        fetchGroupMembers();
      } else {
        fetchUserDetails();
      }

      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          showEmojiPicker.value = false;
        }
      });

      _pinWorker = ever(messages, (List<MessageModel> msgs) {
        final pinned = msgs.firstWhereOrNull((m) => m.isPinned);
        activePinnedMessage.value = pinned;
      });
    } catch (e) {
      print("Error in ChatController init: $e");
    }
  }

  @override
  void onClose() {
    // 1. متوقف کردن لیسنرهای GetX
    _msgWorker?.dispose();
    _typingWorker?.dispose();
    _pinWorker?.dispose();
    _debounce?.cancel();
    _recordTimer?.cancel();

    // 2. حذف لیسنرهای سوکت (جلوگیری از تکرار پیام و سین خوردن اشتباه)
    socketService.socket?.off("messages_seen");
    socketService.socket?.off("reaction_update");
    socketService.socket?.off("message_pinned");
    socketService.socket?.off("message_unpinned");
    socketService.socket?.off("message_updated");
    socketService.socket?.off("message_deleted");

    // 3. آزادسازی منابع
    recorderController.dispose();
    reviewPlayerController.dispose();

    super.onClose();
  }

  void listenToNewSocketEvents() {
    // حذف لیسنرهای احتمالی قبلی برای اطمینان
    socketService.socket?.off("reaction_update");

    socketService.socket?.on("reaction_update", (data) {
      final int msgId = data['messageId'];
      final int userId = data['userId'];
      final String? reaction = data['reaction'];

      final index = messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        var msg = messages[index];
        var newReactions = List<ReactionModel>.from(msg.reactions);
        newReactions.removeWhere((r) => r.userId == userId);
        if (reaction != null) {
          newReactions.add(ReactionModel(userId: userId, reaction: reaction));
        }
        msg.reactions = newReactions;
        messages[index] = msg;
        messages.refresh();
      }
    });

    socketService.socket?.on("message_pinned", (data) {
      _updateMessagePinStatus(data['messageId'], true);
    });

    socketService.socket?.on("message_unpinned", (data) {
      _updateMessagePinStatus(data['messageId'], false);
    });

    socketService.socket?.on("message_updated", (data) {
      final int msgId = data['messageId'];
      final index = messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        messages[index].content = data['newContent'];
        messages[index].isEdited = true;
        messages.refresh();
      }
    });

    socketService.socket?.on("message_deleted", (data) {
      messages.removeWhere((m) => m.id == data['messageId']);
    });
  }

  void _updateMessagePinStatus(int msgId, bool isPinned) {
    final index = messages.indexWhere((m) => m.id == msgId);
    if (index != -1) {
      var msg = messages[index];
      msg.isPinned = isPinned;
      messages[index] = msg;

      if (isPinned) {
        activePinnedMessage.value = msg;
      } else {
        if (activePinnedMessage.value?.id == msgId) {
          activePinnedMessage.value = null;
        }
      }
      messages.refresh();
    }
  }

  Future<void> pickAndSendMedia(ImageSource source,
      {bool isVideo = false,}) async {
    final ImagePicker picker = ImagePicker();
    XFile? media;

    if (isVideo) {
      media = await picker.pickVideo(source: source);
    } else {
      media = await picker.pickImage(source: source, imageQuality: 70);
    }

    if (media != null) {
      File file = File(media.path);
      // ارسال نوع فایل (IMAGE یا VIDEO)
      _uploadAndSend(file, isVideo ? 'VIDEO' : 'IMAGE');
    }
  }

  Future<void> _uploadAndSend(File file, String type) async {
    String localPath = file.path;
    uploadingFiles[localPath] = 0.0;

    // بدست آوردن حجم فایل برای نمایش در چت
    int fileSize = await file.length();

    String? url = await globalController.uploadFile(file, onProgress: (val) {
      uploadingFiles[localPath] = val;
    },);

    uploadingFiles.remove(localPath);

    if (url != null) {
      sendMessage(type: type,
        fileUrl: url,
        contentOverride: type == 'VOICE' ? 'Voice' : (type == 'VIDEO'
            ? 'Video'
            : ''),
        fileSize: fileSize,);
    } else {
      Get.snackbar("خطا", "آپلود فایل با مشکل مواجه شد");
    }
  }

  bool onBackPress() {
    if (showEmojiPicker.value) {
      showEmojiPicker.value = false;
      return false; // جلوگیری از خروج از صفحه
    }
    return true; // اجازه خروج
  }

  void fetchGroupMembers() async {
    try {
      final response = await http.get(
        Uri.parse("${ChatGlobalController.baseUrl}/groups/$targetId/members"),
        headers: globalController.headers,);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final members = data.map((e) => ChatUser.fromJson(e)).toList();
        groupMembers.assignAll(members);

        // شمارش آنلاین‌ها
        onlineCount.value = members
            .where((u) => u.isOnline)
            .length;
      }
    } catch (e) {
      print("Fetch Members Error: $e");
    }
  }

  Future<void> toggleBlock() async {
    bool success;
    if (isBlocked.value) {
      success = await globalController.unblockUser(targetId);
    } else {
      success = await globalController.blockUser(targetId);
    }
    if (success) {
      isBlocked.toggle();
      Get.back(); // بستن منو
      Get.snackbar(
        "موفق", isBlocked.value ? "کاربر مسدود شد" : "کاربر رفع مسدودیت شد",);
    }
  }

  Future<void> deleteThisChat() async {
    await globalController.deleteConversation(targetId, isGroup);
    Get.offAllNamed("/inbox"); // برگشت به اینباکس
  }

  void fetchUserDetails() async {
    final details = await globalController.getUserDetails(targetId);
    if (details != null) {
      userFullName.value = details['fullName'] ?? "";
      userUsername.value = details['username'] ?? "";
      userBio.value = details['bio'] ?? "";
      userAvatar.value = details['avatarUrl'];
      isOnline.value = details['isOnline'] ?? false;
      isBlocked.value = details['isBlocked'] ?? false;
    }
  }

  void _ensureConnection() {
    if (socketService.socket?.connected != true) {
      if (globalController.token != null) {
        socketService.connect(globalController.token!);
      }
    } else {
      if (!isGroup) socketService.markSeen(targetId);
    }
  }

  RxBool loading = false.obs;

  void loadMessages() async {
    loading.value = false;
    var history = await globalController.getChatHistory(
      targetId, isGroup: isGroup,);
    messages.assignAll(history);
    loading.value = true;
  }

  var activePinnedMessage = Rxn<MessageModel>();

  void listenToSocket() {
    socketService.socket?.on("messages_seen", (data) {
      // فقط اگر صفحه باز است رفرش کن
      bool changed = false;
      for (var msg in messages) {
        if (!msg.isSeen && msg.senderId == globalController.currentUserId) {
          msg.isSeen = true;
          changed = true;
        }
      }
      if (changed) messages.refresh();
    });

    _msgWorker = ever(socketService.newMessageReceived, (MessageModel? msg) {
      if (msg == null) return;

      final currentUserId = globalController.currentUserId;
      bool isRelevant = false;

      if (isGroup) {
        isRelevant = (msg.groupId == targetId);
      } else {
        if (msg.senderId == currentUserId) {
          isRelevant = (msg.receiverId == targetId);
        } else {
          isRelevant = (msg.senderId == targetId);
        }
      }

      if (isRelevant) {
        int index = messages.indexWhere((m) => m.id == msg.id);

        // جلوگیری از تکرار برای پیام‌های ارسالی خودم (tempId)
        if (index == -1 && msg.senderId == currentUserId) {
          index = messages.indexWhere((m) =>
          (m.status == MessageStatus.sending ||
              m.status == MessageStatus.sent) && m.content == msg.content &&
              m.type == msg.type, // اضافه کردن type برای دقت بالاتر در مچ کردن
          );
        }

        if (index != -1) {
          // پیام قبلاً هست، آپدیتش کن
          messages[index] = msg;
          messages.refresh();
        } else {
          // پیام جدید است، اضافه کن
          messages.insert(0, msg);

          // >>>>>> نکته کلیدی: سین زدن فقط وقتی پیام جدید میاد <<<<<<
          if (!isGroup && msg.senderId == targetId) {
            socketService.markSeen(targetId);
            globalController.markChatAsRead(targetId, isGroup);
          }
        }
      }
    });

    _typingWorker =
        ever(socketService.typingStatus, (Map<String, dynamic>? data,) {
          if (data != null && data['senderId'] == targetId && !isGroup) {
            isTyping.value = data['isTyping'];
          }
        });
  }

  void onTextChanged(String val) {
    showSendButton.value = val.isNotEmpty;
    if (isGroup) return;

    socketService.sendTyping(targetId, true);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      socketService.sendTyping(targetId, false);
    });
  }

  void replyToMessage(MessageModel msg) {
    replyMessage.value = msg;
  }

  void sendMessage(
      {String type = 'TEXT', String? fileUrl, String? contentOverride, int? fileSize,}) async {
    String content = contentOverride ?? textCtrl.text.trim();
    if (content.isEmpty && fileUrl == null) return;

    // A. اگر در حالت ویرایش هستیم:
    if (isEditing.value && editingMessageId.value != null) {
      _submitEditMessage(content);
      return;
    }

    // B. ارسال پیام جدید
    final tempId = DateTime
        .now()
        .millisecondsSinceEpoch; // آیدی موقت

    // ساخت مدل پیام برای نمایش فوری در لیست (Optimistic UI)
    final newMessage = MessageModel(
      id: tempId,
      // موقت
      senderId: globalController.currentUserId,
      receiverId: isGroup ? null : targetId,
      groupId: isGroup ? targetId : null,
      content: content,
      type: type,
      fileUrl: fileUrl,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      // در حال ارسال
      parent: replyMessage.value,);

    messages.insert(0, newMessage);

    final fcm = await PrefHelpers.getFcm();
    // آماده‌سازی داده برای سوکت
    Map<String, dynamic> data = {
      'tempId': tempId,
      // برای مچ کردن پاسخ (اختیاری)
      'content': content,
      'type': type,
      'fileUrl': fileUrl,
      'parentId': replyMessage.value?.id,
      'fileSize': fileSize,
      'fcmToken': fcm,
    };

    if (isGroup) {
      data['groupId'] = targetId;
    } else {
      data['receiverId'] = targetId;
    }

    _emitMessage(data, tempId, index: 0);

    // پاکسازی ورودی‌ها
    if (type == 'TEXT') textCtrl.clear();
    replyMessage.value = null;
    showSendButton.value = false;
  }

  // متد کمکی برای emit کردن با مدیریت خطا
  void _emitMessage(Map<String, dynamic> data, int tempId,
      {required int index,}) {
    if (socketService.socket?.connected == true) {
      socketService.socket!.emit("send_message", data);

      Future.delayed(const Duration(milliseconds: 500), () {
        int realIndex = messages.indexWhere((m) => m.id == tempId);
        if (realIndex != -1) {
          messages[realIndex].status = MessageStatus.sent;
          messages.refresh();
        }
      });
    } else {
      // اگر سوکت قطع بود
      if (index < messages.length) {
        messages[index].status = MessageStatus.failed;
        messages.refresh();
      }
    }
  }

  // --- 3. تلاش مجدد (Retry) ---
  void retryMessage(MessageModel msg) async {
    // پیدا کردن پیام در لیست
    final index = messages.indexOf(msg);
    if (index == -1) return;

    // تغییر وضعیت به در حال ارسال
    msg.status = MessageStatus.sending;
    messages[index] = msg;
    messages.refresh();
    final fcm = await PrefHelpers.getFcm();

    Map<String, dynamic> data = {
      'content': msg.content,
      'type': msg.type,
      'fileUrl': msg.fileUrl,
      'parentId': msg.parent?.id,
      'fileSize': msg.fileSize,
      'fcmToken': fcm,
    };
    if (isGroup) {
      data['groupId'] = targetId;
    } else {
      data['receiverId'] = targetId;
    }

    _emitMessage(data, msg.id!, index: index);
  }

  // --- 4. ویرایش پیام ---
  void startEditing(MessageModel msg) {
    isEditing.value = true;
    editingMessageId.value = msg.id;
    textCtrl.text = msg.content;
    showSendButton.value = true;
    focusNode.requestFocus();
  }

  void cancelEditing() {
    isEditing.value = false;
    editingMessageId.value = null;
    textCtrl.clear();
    showSendButton.value = false;
    focusNode.unfocus();
  }

  void _submitEditMessage(String newContent) {
    if (editingMessageId.value == null) return;

    socketService.socket?.emit("edit_message", {
      "messageId": editingMessageId.value,
      "newContent": newContent,
      "receiverId": isGroup ? null : targetId,
      "groupId": isGroup ? targetId : null,
    });

    // آپدیت لوکال
    final index = messages.indexWhere((m) => m.id == editingMessageId.value);
    if (index != -1) {
      messages[index].content = newContent;
      messages[index].isEdited = true;
      messages.refresh();
    }

    cancelEditing();
  }

  // --- 5. ری‌اکشن ---
  void reactToMessage(int messageId, String reaction) {
    socketService.socket?.emit("add_reaction", {
      "messageId": messageId,
      "reaction": reaction,
      "receiverId": isGroup ? null : targetId,
      "groupId": isGroup ? targetId : null,
    });
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  // --- 6. پین کردن ---
  void pinMessage(int messageId) {
    socketService.socket?.emit("pin_message",
        {"messageId": messageId, "receiverId": isGroup ? null : targetId,});
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  // --- 7. فوروارد ---
  void forwardMessage(int originalMsgId, int targetUserId,
      {bool isTargetGroup = false,}) {
    socketService.socket?.emit("forward_message", {
      "originalMessageId": originalMsgId,
      "receiverId": isTargetGroup ? null : targetUserId,
      "groupId": isTargetGroup ? targetUserId : null,
    });
    Get.back(); // بستن دیالوگ انتخاب کاربر
    Get.snackbar("موفق", "پیام فوروارد شد");
  }

  Future<void> addNewMember(int userId) async {
    final success = await globalController.addGroupMember(targetId, userId);
    if (success) {
      Get.back(); // بستن دیالوگ انتخاب کاربر
      fetchGroupMembers(); // رفرش لیست اعضا
      Get.snackbar("موفق", "کاربر به گروه اضافه شد");
    }
  }

  // 2. متد حذف کاربر (Kick)
  Future<void> kickUser(int userId, String userName) async {
    Get.defaultDialog(title: "Delete user",
      middleText: "Are you sure you want to remove $userName from the group?",
      textConfirm: "Yes, delete it",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back(); // بستن دیالوگ
        final success = await globalController.kickGroupMember(
          targetId, userId,);
        if (success) {
          fetchGroupMembers(); // رفرش لیست
          Get.snackbar("انجام شد", "$userName از گروه حذف شد");
        }
      },);
  }

  // 3. چک کردن اینکه آیا من ادمین هستم؟
  bool get amIAdmin {
    final myId = globalController.currentUserId;
    // پیدا کردن خودم در لیست اعضا
    final me = groupMembers.firstWhereOrNull((u) => u.id == myId);
    return me?.isAdmin ?? false;
  }

  // 4. دریافت لیست کاربرانی که عضو گروه نیستند (برای افزودن)
  List<ChatUser> getPotentialMembers() {
    // همه یوزرها منهای کسانی که الان عضو هستند
    final currentMemberIds = groupMembers.map((e) => e.id).toSet();
    return globalController.allUsers.where((u) =>
    !currentMemberIds.contains(u.id)).toList();
  }

  // --- Recording Logic ---

  Future<void> startRecording() async {
    if (await Permission.microphone
        .request()
        .isGranted) {
      // ویبره کوتاه برای فیدبک
      HapticFeedback.mediumImpact();

      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/rec_${DateTime
          .now()
          .millisecondsSinceEpoch}.m4a";

      // تنظیمات رکوردر برای داشتن Waveform
      await recorderController.record(path: path);

      isRecording.value = true;
      isRecordingLocked.value = false;
      isReviewing.value = false;
      recordDuration.value = 0;

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordDuration.value++;
      });
    }
  }

  void lockRecording() {
    if (isRecording.value && !isRecordingLocked.value) {
      isRecordingLocked.value = true;
    }
  }

  Future<void> stopForReview() async {
    if (isRecording.value) {
      final path = await recorderController.stop();
      _recordTimer?.cancel();

      if (path != null) {
        recordedFilePath = path;
        isRecording.value = false;
        isRecordingLocked.value = false;
        isReviewing.value = true; // فعال کردن حالت بازبینی

        // آماده‌سازی پلیر برای بازبینی (اختیاری)
        await reviewPlayerController.preparePlayer(
          path: path, shouldExtractWaveform: true,);
      } else {
        resetRecordingState();
      }
    }
  }

  Future<void> cancelAndDeleteRecording() async {
    // اگر در حال ضبط است متوقف کن
    if (isRecording.value) {
      await recorderController.stop();
    }

    // فایل را پاک کن
    if (recordedFilePath != null) {
      File(recordedFilePath!).delete().ignore();
    }

    resetRecordingState();
  }

  // 5. ارسال نهایی فایل ضبط شده
  Future<void> sendRecordedFile() async {
    // اگر هنوز در حال ضبط است (حالت قفل)، اول متوقف کن
    if (isRecording.value) {
      recordedFilePath = await recorderController.stop();
    }

    if (recordedFilePath != null) {
      File file = File(recordedFilePath!);
      if (await file.exists()) {
        _uploadAndSend(file, 'VOICE');
      }
    }

    resetRecordingState();
  }

  void resetRecordingState() {
    isRecording.value = false;
    isRecordingLocked.value = false;
    isReviewing.value = false;
    recordDuration.value = 0;
    recordedFilePath = null;
    _recordTimer?.cancel();
  }

  var isSearching = false.obs;
  final TextEditingController searchCtrl = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  var searchResultsIds = <int>[].obs; // لیست آیدی پیام‌های پیدا شده
  var currentSearchIndex = 0.obs; // ایندکس پیام فعلی در نتایج

  void toggleSearchMode() {
    isSearching.toggle();
    if (isSearching.value) {
      searchFocusNode.requestFocus();
    } else {
      // خروج از جستجو
      searchCtrl.clear();
      searchResultsIds.clear();
      currentSearchIndex.value = 0;
      searchFocusNode.unfocus();
    }
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      searchResultsIds.clear();
      return;
    }
    // جستجو در لیست فعلی پیام‌ها (کلاینت ساید)
    // نکته: اگر نیاز به جستجو در سمت سرور دارید باید API کال کنید
    final results = messages.where((m) => m.content.contains(query)).map((
        e) => e.id!).toList();

    // چون لیست مسیج معکوس نمایش داده میشه، ما نتایج رو هم مدیریت میکنیم
    searchResultsIds.assignAll(results);

    if (searchResultsIds.isNotEmpty) {
      currentSearchIndex.value = 0;
      scrollToMessage(searchResultsIds[0]);
    }
  }

  void nextSearchResult() {
    if (searchResultsIds.isEmpty) return;
    if (currentSearchIndex.value < searchResultsIds.length - 1) {
      currentSearchIndex.value++;
      scrollToMessage(searchResultsIds[currentSearchIndex.value]);
    }
  }

  void prevSearchResult() {
    if (searchResultsIds.isEmpty) return;
    if (currentSearchIndex.value > 0) {
      currentSearchIndex.value--;
      scrollToMessage(searchResultsIds[currentSearchIndex.value]);
    }
  }
}

class ChatScreen extends StatelessWidget {
  final int targetId;
  final bool isGroup;
  final String name;
  final String? avatarUrl;

  const ChatScreen(
      {super.key, required this.targetId, required this.isGroup, required this.name, this.avatarUrl,});

  @override
  Widget build(BuildContext context) {
    // ایجاد کنترلر
    final controller = Get.put(
      ChatScreenController(targetId: targetId, isGroup: isGroup),
      tag: "chat_$targetId",);

    // پر کردن اطلاعات اولیه
    if (controller.userFullName.value.isEmpty) {
      controller.userFullName.value = name;
    }
    if (controller.userAvatar.value == null) {
      controller.userAvatar.value = avatarUrl;
    }

    const primaryColor = Color(0xff969bff);
    final Color secondaryColor = Color(0xffA78BFA);
    const bgColor = Color(0xffF0F2F5); // رنگ پس‌زمینه شبیه واتساپ/تلگرام دسکتاپ

    return GestureDetector(onTap: () {
      controller.showEmojiPicker.value = false;
      FocusManager.instance.primaryFocus?.unfocus();
    },
      child: Scaffold(backgroundColor: bgColor,
        appBar: _buildModernAppBar(context, controller, primaryColor),
        body: Container(decoration: BoxDecoration(image: DecorationImage(
          image: AssetImage(Assets.imagesChatBG),
          fit: .cover,
          opacity: 0.15,),), child: Column(children: [
          Obx(() {
            if (controller.activePinnedMessage.value == null) {
              return const SizedBox.shrink();
            }
            final pinnedMsg = controller.activePinnedMessage.value!;
            return GestureDetector(
              onTap: () => controller.scrollToMessage(pinnedMsg.id!),
              child: Container(width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8,),
                decoration: BoxDecoration(
                  color: Colors.white, border: Border(bottom: BorderSide(
                    color: Colors.grey.shade200),), boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),),
                ],),
                child: Row(children: [Container(width: 4,
                  height: 30,
                  decoration: BoxDecoration(color: const Color(0xff969bff),
                    borderRadius: BorderRadius.circular(2),),), const SizedBox(
                    width: 12), Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pinned message", style: TextStyle(
                      color: Color(0xff969bff),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,),),
                    const SizedBox(height: 2),
                    Text(pinnedMsg.type == 'TEXT'
                        ? pinnedMsg.content
                        : "Media file", maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13, color: Colors.black87,),),
                  ],),), IconButton(icon: const Icon(
                  Icons.close, size: 18, color: Colors.grey,), onPressed: () {
                  controller.pinMessage(pinnedMsg.id!);
                },),
                ],),),);
          }),

          Expanded(child: Obx(() {
            if (controller.loading.isFalse) {
              return Center(
                child: Lottie.asset(Assets.animAnimLoading, height: 100),);
            }
            return ListView.builder(reverse: true,
              // چون لیست چت معکوس است
              controller: controller.scrollCtrl,
              // کنترلر جدید را وصل کنید
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16,),
              itemCount: controller.messages.length,
              itemBuilder: (ctx, index) {
                final msg = controller.messages[index];
                final currentUserId = controller.globalController
                    .currentUserId ?? 0;
                final isMe = msg.senderId == currentUserId;

                // 3. رپ کردن آیتم لیست در AutoScrollTag
                return AutoScrollTag(key: ValueKey(index),
                  controller: controller.scrollCtrl,
                  index: index,
                  highlightColor: Colors.black.withOpacity(0.1),
                  // رنگ هایلایت هنگام پرش
                  child: SwipeTo(key: ValueKey(msg.id),
                    onRightSwipe: (v) => controller.replyToMessage(msg),
                    iconOnRightSwipe: Icons.reply_rounded,
                    iconColor: primaryColor,
                    child: _ModernMessageBubble(
                      message: msg, isMe: isMe, controller: controller,),),);
              },).animate().fadeIn(duration: Duration(milliseconds: 500));
          }),),

          Obx(() {
            if (controller.replyMessage.value == null) {
              return const SizedBox.shrink();
            }
            return _buildReplyPreview(controller, primaryColor);
          }),

          // بخش آپلود فایل
          Obx(() {
            if (controller.uploadingFiles.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5,),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),),
              child: Row(children: [
                const SizedBox(
                  width: 10, height: 10, child: CircularProgressIndicator(
                    strokeWidth: 2),),
                const SizedBox(width: 10),
                const Text("Sending file...", style: TextStyle(fontSize: 12),),
                const Spacer(),
                Text("${(controller.uploadingFiles.values.first * 100)
                    .toInt()}%", style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold,),),
              ],),);
          }),
          // بخش ورودی پیام
          _ModernInputArea(controller: controller, primaryColor: primaryColor,),
          Obx(() {
            if (!controller.showEmojiPicker.value) {
              return const SizedBox.shrink();
            }

            return SizedBox(height: 256,
              child: EmojiPicker(
                onEmojiSelected: (Category? category, Emoji emoji) {
                  // اضافه کردن ایموجی به متن و نگه‌داشتن مکان نما
                  controller.textCtrl.text =
                      controller.textCtrl.text + emoji.emoji;
                  controller.onTextChanged(controller.textCtrl
                      .text,); // آپدیت دکمه ارسال
                },
                onBackspacePressed: () {
                  // پیاده‌سازی بک‌اسپیس
                  controller.textCtrl
                    ..text = controller.textCtrl.text.characters.skipLast(1)
                        .toString()
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.textCtrl.text.length),);
                  controller.onTextChanged(controller.textCtrl.text);
                },
                textEditingController: controller.textCtrl,
                config: Config(height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(backgroundColor: const Color(
                    0xffF0F2F5,), // هماهنگ با تم
                    columns: 7, emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.20
                            : 1.0),),
                  viewOrderConfig: const ViewOrderConfig(top: EmojiPickerItem
                      .searchBar, // سرچ بار بالا باشد بهتر است
                    middle: EmojiPickerItem.emojiView, bottom: EmojiPickerItem
                        .categoryBar,),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(
                    backgroundColor: Colors.white,
                    dividerColor: Colors.white,
                    indicatorColor: primaryColor,
                    // رنگ سبز شما
                    iconColorSelected: primaryColor,
                    iconColor: Colors.grey,),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    enabled: false,
                    // مخفی کردن دکمه‌های اضافی پایین
                    backgroundColor: Colors.white,
                    buttonColor: Colors.white,
                    buttonIconColor: Colors.grey,),
                  searchViewConfig: const SearchViewConfig(
                    backgroundColor: Color(0xffF0F2F5),),),),);
          }),
        ],),),),);
  }

  void _showUserProfile(BuildContext context, ChatScreenController controller) {
    Get.bottomSheet(Container(decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // آواتار بزرگ
        if (controller.userAvatar.value != null)ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: FastCachedImage(url: controller.userAvatar.value!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,),),
        const SizedBox(height: 15),
        // نام
        Text(controller.userFullName.value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        const SizedBox(height: 5),
        // نام کاربری (شماره)
        Text(controller.userUsername.value,
          style: const TextStyle(fontSize: 14, color: Colors.grey),),
        const SizedBox(height: 15),
        const Divider(),
        // بیو
        if (controller.userBio.value.isNotEmpty) ...[
          const Align(alignment: Alignment.centerRight,
            child: Text(
              "Bio", style: TextStyle(fontWeight: FontWeight.bold),),),
          const SizedBox(height: 5),
          Align(alignment: Alignment.centerRight,
            child: Text(controller.userBio.value,
              style: const TextStyle(fontSize: 14),),),
          const SizedBox(height: 20),
        ],
        // دکمه‌های عملیات
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionBtn(
              Icons.block, controller.isBlocked.value ? "Unblock" : "Block",
              Colors.red, controller.toggleBlock,),
            _buildActionBtn(Icons.delete, "Delete chat", Colors.red,
              controller.deleteThisChat,),
          ],),
      ],),), isScrollControlled: true,);
  }

  Widget _buildActionBtn(IconData icon, String label, Color color,
      VoidCallback onTap,) {
    return InkWell(onTap: onTap,
      child: Column(children: [
        CircleAvatar(radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],),);
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context,
      ChatScreenController controller, Color color,) {
    return AppBar(backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      leadingWidth: 40,
      leading: Padding(padding: const EdgeInsets.only(right: 10),
        child: IconButton(icon: const Icon(
          Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20,),
          onPressed: () {
            if (controller.isSearching.value) {
              controller.toggleSearchMode();
            } else {
              Get.back();
            }
          },),),
      // --- لاجیک تغییر تایتل به سرچ بار ---
      title: Obx(() {
        if (controller.isSearching.value) {
          return TextField(controller: controller.searchCtrl,
            focusNode: controller.searchFocusNode,
            onChanged: (val) => controller.performSearch(val),
            decoration: const InputDecoration(hintText: "Search...",
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            textInputAction: TextInputAction.search,);
        }

        // --- حالت عادی تایتل ---
        return InkWell(onTap: () {
          if (isGroup) {
            _showGroupInfo(context, controller);
          } else {
            _showUserProfile(context, controller);
          }
        },
          child: Row(children: [
            Hero(tag: "avatar_${controller.targetId}",
              child: Container(decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),),
                child: CircleAvatar(radius: 20,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: controller.userAvatar.value != null
                      ? FastCachedImageProvider(controller.userAvatar.value!)
                      : null,
                  child: controller.userAvatar.value == null ? Text(
                    controller.userFullName.value.isNotEmpty ? controller
                        .userFullName.value[0] : "?",
                    style: TextStyle(color: color, fontWeight: FontWeight
                        .bold,),) : null,),),),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.userFullName.value, style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,),
                  overflow: TextOverflow.ellipsis,),
                if (controller.isTyping.value)Text("writing...",
                  style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight
                      .w600,),) else
                  if (isGroup)Text("${controller.groupMembers.length} Member",
                    style: TextStyle(color: Colors.grey.shade600,
                      fontSize: 11,),) else
                    Text(controller.isOnline.value
                        ? "Online"
                        : "Last visited recently", style: TextStyle(
                      color: controller.isOnline.value ? color : Colors.grey
                          .shade500,
                      fontSize: 11,
                      fontWeight: controller.isOnline.value
                          ? FontWeight.bold
                          : FontWeight.normal,),),
              ],),),
          ],),);
      }),
      actions: [Obx(() {
        // --- دکمه‌های کنترل جستجو (بالا/پایین) ---
        if (controller.isSearching.value) {
          return Row(mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.searchResultsIds.isNotEmpty)Text(
                "${controller.currentSearchIndex.value + 1} from ${controller
                    .searchResultsIds.length}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),),
              IconButton(icon: const Icon(
                Icons.keyboard_arrow_up, color: Colors.black54,),
                onPressed: controller.nextSearchResult,),
              IconButton(icon: const Icon(
                Icons.keyboard_arrow_down, color: Colors.black54,),
                onPressed: controller.prevSearchResult,),
            ],);
        }

        // --- دکمه‌های عادی AppBar ---
        return Row(children: [
          if (!isGroup)IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black87),
            onPressed: () async {
              final c = Get.put(CallController());
              c.onInit();
              await c.startCall(targetId, name, avatarUrl);
            },),
          Directionality(textDirection: TextDirection.ltr,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black87,),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),),
              onSelected: (value) {
                if (value == 'search') {
                  controller.toggleSearchMode(); // <--- دکمه سرچ
                }
                if (value == 'block') controller.toggleBlock();
                if (value == 'delete') controller.deleteThisChat();
              },
              itemBuilder: (context) =>
              [
                const PopupMenuItem(value: 'search', child: Row(children: [Icon(
                    Icons.search, color: Colors.black54, size: 20), SizedBox(
                    width: 10), Text('Message search'),
                ],),),
                PopupMenuItem(value: 'block', child: Row(children: [
                  Icon(controller.isBlocked.value
                      ? Icons.check_circle_outline
                      : Icons.block, color: Colors.red, size: 20,),
                  const SizedBox(width: 10),
                  Text(controller.isBlocked.value ? 'Unblock' : 'Block',),
                ],),),
                const PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(
                    Icons.delete_forever_rounded, color: Colors.red, size: 20,),
                  SizedBox(width: 10),
                  Text('Delete history'),
                ],),),
              ],),),
        ],);
      }),
      ],);
  }

  Widget _buildReplyPreview(ChatScreenController controller, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],),
      child: Row(children: [
        Container(width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10),),),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reply to", style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11,),),
            const SizedBox(height: 2),
            Text(controller.replyMessage.value?.content ?? "File", maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),),
          ],),),
        IconButton(icon: const Icon(Icons.close, size: 20, color: Colors.grey),
          onPressed: () => controller.replyMessage.value = null,),
      ],),);
  }

  void _showGroupInfo(BuildContext context, ChatScreenController controller) {
    Get.bottomSheet(Container(decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      padding: const EdgeInsets.symmetric(vertical: 20),
      constraints: BoxConstraints(maxHeight: Get.height * 0.8),
      child: Column(children: [
        // --- هدر ---
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            if (controller.userAvatar.value != null)CircleAvatar(radius: 25,
              backgroundImage: FastCachedImageProvider(
                controller.userAvatar.value!,),),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.userFullName.value, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18,),),
                Obx(() =>
                    Text("${controller.groupMembers.length} Members",
                      style: const TextStyle(color: Colors.grey),),),
              ],),),

            // --- دکمه افزودن کاربر (متصل شد) ---
            IconButton(
              icon: const Icon(Icons.person_add, color: Color(0xff969bff),),
              onPressed: () {
                _showAddMemberSheet(context, controller);
              },),
          ],),), const Divider(),

        // --- لیست اعضا ---
        Expanded(child: Obx(() {
          final amIAdmin = controller.amIAdmin; // آیا من ادمین هستم؟
          final myId = controller.globalController.currentUserId;

          return ListView.builder(itemCount: controller.groupMembers.length,
            itemBuilder: (ctx, index) {
              final member = controller.groupMembers[index];
              final isMe = member.id == myId;

              return ListTile(leading: Stack(children: [CircleAvatar(
                backgroundImage: member.avatarUrl != null
                    ? FastCachedImageProvider(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? Text(
                  member.fullName.isNotEmpty ? member.fullName[0] : "?",)
                    : null,), if (member.isOnline)Positioned(right: 0,
                bottom: 0,
                child: Container(width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2,),),),),
              ],),
                title: Row(children: [Text(member.fullName), if (member
                    .isAdmin) ...[
                  const SizedBox(width: 5),
                  const Text("(Admin)", style: TextStyle(
                    color: Color(0xff969bff),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,),),
                ], if (isMe)const Text(" (Me)",
                  style: TextStyle(color: Colors.grey, fontSize: 12,),),
                ],),
                subtitle: Text(member.isOnline ? "Online" : "last visit...",),

                // --- دکمه حذف (فقط اگر من ادمینم و طرف مقابل خودم نیستم) ---
                trailing: (amIAdmin && !isMe) ? IconButton(icon: const Icon(
                  Icons.remove_circle_outline, color: Colors.red,),
                  onPressed: () {
                    controller.kickUser(member.id, member.fullName);
                  },) : null,);
            },);
        }),),
      ],),), isScrollControlled: true,);
  }

  // --- متد جدید: نمایش لیست برای افزودن کاربر ---
  void _showAddMemberSheet(BuildContext context,
      ChatScreenController controller,) {
    // مطمئن شویم لیست همه کاربران به‌روز است
    controller.globalController.fetchAllUsers();

    Get.bottomSheet(Container(height: Get.height * 0.6,
      decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(15),
          child: Text("Add new member",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),),
        const Divider(height: 1),
        Expanded(child: Obx(() {
          // دریافت لیست کسانی که عضو نیستند
          final potentialMembers = controller.getPotentialMembers();

          if (potentialMembers.isEmpty) {
            return const Center(child: Text("There are no users to add"));
          }

          return ListView.builder(
            itemCount: potentialMembers.length, itemBuilder: (ctx, index) {
            final user = potentialMembers[index];
            return ListTile(leading: CircleAvatar(backgroundImage: user
                .avatarUrl != null
                ? FastCachedImageProvider(user.avatarUrl!)
                : null, child: user.avatarUrl == null
                ? Text(user.fullName[0])
                : null,),
              title: Text(user.fullName),
              subtitle: Text(user.username),
              trailing: const Icon(Icons.add_circle, color: Color(0xff969bff),),
              onTap: () {
                controller.addNewMember(user.id);
              },);
          },);
        }),),
      ],),), isScrollControlled: true,);
  }
}

class _AnimatedLock extends StatefulWidget {
  final ChatScreenController controller;
  const _AnimatedLock({required this.controller});

  @override
  State<_AnimatedLock> createState() => _AnimatedLockState();
}

class _AnimatedLockState extends State<_AnimatedLock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), vsync: this,)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      return Transform.translate(offset: Offset(0, -10 * _controller.value),
        child: Opacity(opacity: 0.8,
          child: Column(children: const [
            Icon(Icons.lock_open_rounded, color: Colors.grey, size: 20),
            Icon(
              Icons.keyboard_arrow_up_rounded, color: Colors.grey, size: 20,),
          ],),),);
    },);
  }
}

class _AdvancedVoicePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  const _AdvancedVoicePlayer(
      {super.key, required this.url, required this.isMe,});

  @override
  State<_AdvancedVoicePlayer> createState() => _AdvancedVoicePlayerState();
}

class _AdvancedVoicePlayerState extends State<_AdvancedVoicePlayer> {
  late PlayerController playerController;
  bool isPlaying = false;
  bool isLoading = false; // دیفالت false باشه، موقع prepare true میکنیم
  bool isPrepared = false; // فلگ برای اینکه بفهمیم آماده شده یا نه
  double playbackSpeed = 1.0; // سرعت پیش‌فرض
  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    _loadSavedSpeed(); // لود کردن سرعت ذخیره شده
    _preparePlayer();
  }

  // لود کردن سرعت از حافظه
  Future<void> _loadSavedSpeed() async {
    final savedSpeed = await PrefHelpers
        .getVoiceSpeed(); // فرض بر این است که این متد String یا Double برمی‌گرداند
    if (savedSpeed != null) {
      setState(() {
        playbackSpeed = double.tryParse(savedSpeed.toString()) ?? 1.0;
      });
    }
  }

  void _toggleSpeed() {
    setState(() {
      if (playbackSpeed == 1.0) {
        playbackSpeed = 1.5;
      } else if (playbackSpeed == 1.5) {
        playbackSpeed = 2.0;
      } else {
        playbackSpeed = 1.0;
      }
    });
    PrefHelpers.setVoiceSpeed(playbackSpeed.toString());
  }

  Future<void> _preparePlayer() async {
    if (isPrepared) return;
    if (mounted) setState(() => isLoading = true);

    String path = widget.url;
    try {
      if (path.startsWith("http")) {
        // دانلود فایل
        final dir = await getTemporaryDirectory();
        final fileName = "${widget.url.hashCode}.m4a"; // اسم فایل ساده‌تر
        final file = File('${dir.path}/$fileName');

        if (!await file.exists()) {
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            debugPrint("Download error: ${response.statusCode}");
            return;
          }
        }
        path = file.path;
      }

      // آماده‌سازی پلیر
      await playerController.preparePlayer(path: path,
        shouldExtractWaveform: true,
        noOfSamples: 40,
        // تعداد سمپل کمتر برای سرعت بیشتر
        volume: 1.0,);

      // لیسنر پایان پخش
      playerController.onCompletion.listen((_) {
        if (mounted) setState(() => isPlaying = false);
      });

      playerController.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => isPlaying = state == PlayerState.playing);
      });

      if (mounted) {
        setState(() {
          isPrepared = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Voice Prepare Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    playerController.dispose(); // حتما دیسپوز شود
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.isMe ? Colors.white70 : Colors.grey;
    final activeWaveColor = widget.isMe ? Colors.white : const Color(
        0xff969bff);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 45,
      child: Row(// نکته: mainAxisSize: MainAxisSize.min را حذف کردیم
        // تا Expanded بتواند فضای داده شده در مرحله ۱ را پر کند
        crossAxisAlignment: CrossAxisAlignment.center, children: [
        // 1. دکمه پخش
        GestureDetector(onTap: () async {
          if (!isPrepared) {
            await _preparePlayer();
          }
          if (isPlaying) {
            await playerController.pausePlayer();
          } else {
            await playerController.startPlayer();
          }
        },
          child: CircleAvatar(radius: 18,
            backgroundColor: widget.isMe ? Colors.white24 : Colors.grey[200],
            child: isLoading ? const SizedBox(width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white,),) : Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.isMe ? Colors.white : Colors.black87,
              size: 22,),),),

        const SizedBox(width: 10),

        // 2. ویوفرم (Waveform)
        Expanded(
          child: AudioFileWaveforms(// size را روی infinity نگذارید چون داخل row است، اما چون Expanded دارد مشکلی نیست
            // بهتر است فقط ارتفاع را مشخص کنید
            size: const Size(double.infinity, 30),
            playerController: playerController,
            enableSeekGesture: true,
            waveformType: WaveformType.fitWidth,
            playerWaveStyle: PlayerWaveStyle(fixedWaveColor: waveColor,
              liveWaveColor: activeWaveColor,
              spacing: 4,
              // فاصله بین خطوط موج
              scaleFactor: 200,
              // مقیاس موج
              waveThickness: 2,
              showBottom: true, // نمایش متقارن موج
            ),
            // انیمیشن برای زیباتر شدن لودینگ
            animationDuration: const Duration(milliseconds: 200),),),

        const SizedBox(width: 8),

        // 3. دکمه سرعت
        GestureDetector(onTap: _toggleSpeed,
          child: Container(width: 32,
            // عرض ثابت برای جلوگیری از پرش
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white24 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),),
            alignment: Alignment.center,
            child: Text("${playbackSpeed.toString().replaceAll('.0', '')}x",
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.isMe ? Colors.white : Colors.black87,),),),),
      ],),);
  }
}

class _ModernMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ChatScreenController controller;

  const _ModernMessageBubble(
      {required this.message, required this.isMe, required this.controller,});

  @override
  Widget build(BuildContext context) {
    // رنگ‌ها
    final sentGradient = LinearGradient(colors: [
      const Color(0xff969bff),
      const Color(0xff969bff),
      ColorsHelper.btn2
    ],);
    const receivedColor = Colors.white;

    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(onLongPress: () {
        _showMessageOptions(context, controller, message, isMe);
      },
        onDoubleTap: () => controller.reactToMessage(message.id!, "👍"),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment
              .start,
          children: [
            Stack(clipBehavior: Clip.none,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isMe ? sentGradient : null,
                      color: isMe ? null : receivedColor,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 2),),
                      ],
                      // گوشه‌های پویا (مثل تلگرام)
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(18),),),
                    child: Padding(padding: const EdgeInsets.all(4.0),
                      // پدینگ کلی کم برای عکس
                      child: IntrinsicWidth(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (message.isPinned)Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              Icon(Icons.push_pin, size: 12,
                                color: isMe ? Colors.white70 : Color(
                                    0xff969bff),),
                              const SizedBox(width: 4),
                              Text("pinned", style: TextStyle(fontSize: 10,
                                color: isMe ? Colors.white70 : Color(
                                    0xff969bff),),),
                            ],),),
                          if (message.parent != null)GestureDetector(onTap: () {
                            controller.scrollToMessage(message.parent!.id!,);
                          },
                            child: Container(margin: const EdgeInsets.only(
                              bottom: 6, left: 4, right: 4, top: 4,),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: isMe
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(
                                  color: isMe ? Colors.white : const Color(
                                      0xff969bff), width: 3,),),),
                              child: Text(
                                message.parent!.content.isNotEmpty ? message
                                    .parent!.content : "File", style: TextStyle(
                                color: isMe
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.black87, fontSize: 12,),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,),),),
                          // --- محتوای اصلی ---
                          if (message.type == 'IMAGE' &&
                              message.fileUrl != null)GestureDetector(
                            onTap: () {
                              Get.to(() =>
                                  Scaffold(backgroundColor: Colors.black,
                                    appBar: AppBar(
                                      backgroundColor: Colors.transparent,
                                      iconTheme: const IconThemeData(
                                        color: Colors.white,),),
                                    body: Center(child: FastCachedImage(
                                      url: message.fileUrl!,
                                      fit: BoxFit.contain,),),),);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ConstrainedBox(// محدودیت ارتفاع و عرض برای جلوگیری از کرش
                                constraints: BoxConstraints(maxHeight: 400,
                                  // جلوگیری از عکس‌های خیلی دراز
                                  minWidth: Get.width *
                                      0.4, // حداقل عرض برای زیبایی
                                ),
                                child: FastCachedImage(url: message.fileUrl!,
                                  // نکته مهم: width: double.infinity را حذف کردیم!
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, progress) {
                                    return Container(height: 200,
                                      width: 200,
                                      // یک عرض پیش‌فرض برای لودینگ
                                      color: Colors.grey[300],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: progress.progressPercentage
                                              .value,
                                          color: const Color(0xff969bff),),),);
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(height: 150,
                                      width: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image,
                                        color: Colors.grey,),);
                                  },),),),),

                          if (message.type == 'VIDEO' &&
                              message.fileUrl != null)Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: _VideoMessageBubble(
                              videoUrl: message.fileUrl!,
                              fileSize: (message.fileSize ?? 0),
                              isMe: isMe,),),

                          if (message.type == 'TEXT' &&
                              message.content.isNotEmpty)Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6,),
                            child: Text(message.content, style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: isMe ? Colors.white : Colors.black87,),),),

                          if (message.type == 'VOICE' &&
                              message.fileUrl != null)Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: SizedBox(width: Get.width * 0.65,
                              child: _AdvancedVoicePlayer(url: message.fileUrl!,
                                isMe: isMe,
                                key: ValueKey(message.id),),),),

                          // --- زمان و تیک ---
                          Padding(padding: const EdgeInsets.only(
                            right: 8, bottom: 4, left: 8,),
                            child: Row(mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (message.isEdited)Text("Edited",
                                  style: TextStyle(fontSize: 9,
                                    fontStyle: FontStyle.italic,
                                    color: isMe ? Colors.white70 : Colors
                                        .grey,),),
                                const SizedBox(width: 5),

                                // برای پر کردن فضای خالی اگر متن کوتاه است
                                if (message.type == 'TEXT')const SizedBox(
                                    width: 20),
                                Text(intl.DateFormat('HH:mm',).format(
                                    message.createdAt), style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors
                                      .grey[500],),),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  if (message.status ==
                                      MessageStatus.failed)GestureDetector(
                                    onTap: () =>
                                        controller.retryMessage(message),
                                    child: const Icon(
                                      Icons.refresh, color: Colors.redAccent,
                                      size: 16,),) else
                                    if (message.status ==
                                        MessageStatus.sending)const Icon(
                                      Icons.access_time, size: 14,
                                      color: Colors.white70,) else
                                      Icon(message.isSeen
                                          ? Icons.done_all_rounded
                                          : Icons.check_rounded, size: 16,
                                        color: message.isSeen
                                            ? Colors.white
                                            : Colors.white60,),
                                ],
                              ],),),
                        ],),),),),),

                if (message.reactions.isNotEmpty)Positioned(bottom: -10,
                  left: isMe ? null : 10,
                  right: isMe ? 10 : null,
                  child: Container(padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2,),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                      border: Border.all(color: Colors.grey.shade200),),
                    child: Row(
                      children: message.reactions.take(3).map((r) =>
                          Text(
                        r.reaction, style: const TextStyle(fontSize: 12),),)
                          .toList(),),),),
              ],),
            // فضای خالی برای ری‌اکشن
            if (message.reactions.isNotEmpty) const SizedBox(height: 12),
          ],),),);
  }
}

void _showMessageOptions(BuildContext context, ChatScreenController controller,
    MessageModel msg, bool isMe,) {
  Get.dialog(Align(
    alignment: Alignment.center, // یا Alignment.bottomCenter برای استایل iOS
    child: Material(color: Colors.transparent,
      child: Container(width: Get.width * 0.85,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,),
          ],),
        child: Directionality(textDirection: .ltr,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 1. بخش ری‌اکشن‌ها (با پس‌زمینه متفاوت)
            Container(padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),),),
              height: 80,
              child: ListView(scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: ["❤️", "👍", "😂", "😮", "😢", "🔥", "🙏", "😡"].map((
                    emoji) {
                  return GestureDetector(onTap: () {
                    Get.back();
                    controller.reactToMessage(msg.id!, emoji);
                  }, child: Container(width: 45,
                    height: 45,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),),
                      ],),
                    alignment: Alignment.center,
                    child: Text(
                      emoji, style: const TextStyle(fontSize: 24),),),);
                }).toList(),),),
            const Divider(height: 1, thickness: 1),

            // 2. لیست گزینه‌ها
            _buildPopupMenuItem(icon: Icons.reply_rounded,
              text: "Reply",
              color: Colors.black87,
              onTap: () {
                Get.back();
                controller.replyToMessage(msg);
              },),
            if (isMe && msg.type == 'TEXT')_buildPopupMenuItem(
              icon: Icons.edit_note_rounded,
              text: "Edit",
              color: Colors.black87,
              onTap: () {
                Get.back();
                controller.startEditing(msg);
              },),

            _buildPopupMenuItem(icon: Icons.forward_to_inbox_rounded,
              text: "Forward",
              color: Colors.black87,
              onTap: () {
                Get.back();
                _showForwardDialog(controller, msg.id!);
              },),

            _buildPopupMenuItem(
              icon: msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              text: msg.isPinned ? "UnPin" : "Pin",
              color: Colors.orange[800]!,
              onTap: () =>
                  controller.pinMessage(
                    msg.id!,), // بستن دیالوگ داخل کنترلر هندل شده
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),

            if (isMe)_buildPopupMenuItem(icon: Icons.delete_outline_rounded,
              text: "Delete message",
              color: Colors.red,
              onTap: () {
                Get.back();
                Get.defaultDialog(title: "Delete message",
                  middleText: "are you sure?",
                  textConfirm: "Yes",
                  textCancel: "No",
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back(); // بستن دیالوگ تایید
                    controller.globalController.deleteMessageForEveryone(msg
                        .id!,);
                  },);
              },),
          ],),),),),), barrierColor: Colors.black54,
    // تار کردن پس‌زمینه برای تمرکز
    transitionDuration: const Duration(milliseconds: 200),);
}

// ویجت کمکی برای آیتم‌های منو
Widget _buildPopupMenuItem(
    {required IconData icon, required String text, required Color color, required VoidCallback onTap,}) {
  return InkWell(onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 15),
        Text(text, style: TextStyle(
          color: color, fontSize: 16, fontWeight: FontWeight.w500,),),
      ],),),);
}

// --- دایالوگ انتخاب برای فوروارد ---
void _showForwardDialog(ChatScreenController controller, int msgId) {
  // اطمینان از لود بودن یوزرها
  controller.globalController.fetchAllUsers();

  Get.bottomSheet(Container(height: Get.height * 0.7,
    decoration: const BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
    child: Directionality(textDirection: .ltr,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(15),
          child: Text(
            "Forward to...", style: TextStyle(fontWeight: FontWeight.bold),),),
        Expanded(child: Obx(() {
          var users = controller.globalController.allUsers;
          return ListView.builder(
            itemCount: users.length, itemBuilder: (ctx, i) {
            return ListTile(
              leading: CircleAvatar(backgroundImage: FastCachedImageProvider(
                users[i].avatarUrl ?? "",),),
              title: Text(users[i].fullName),
              onTap: () => controller.forwardMessage(msgId, users[i].id),);
          },);
        }),),
      ],),),), isScrollControlled: true,);
}

class _ModernInputArea extends StatelessWidget {
  final ChatScreenController controller;
  final Color primaryColor;

  const _ModernInputArea(
      {super.key, required this.controller, required this.primaryColor,});

  @override
  Widget build(BuildContext context) {
    final isEmojiOpen = controller.showEmojiPicker.value;
    return Obx(() {
      // 1. اگر در حال بازبینی هستیم (ضبط تمام شده ولی ارسال نشده)
      if (controller.isReviewing.value) {
        return _buildReviewUI();
      }

      // 2. اگر ضبط قفل شده است
      if (controller.isRecordingLocked.value) {
        return _buildLockedRecordingUI(isEmojiOpen);
      }

      // 3. حالت عادی یا ضبط با نگه داشتن (بدون قفل)
      return _buildNormalOrHoldRecordingUI(context, isEmojiOpen);
    });
  }

  // --- UI حالت بازبینی (Review Mode) ---
  Widget _buildReviewUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(children: [
        // دکمه حذف
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => controller.cancelAndDeleteRecording(),),

        // ویوفرم فایل ضبط شده (استاتیک یا با پلیر دوم)
        Expanded(child: Container(height: 40,
          decoration: BoxDecoration(color: const Color(0xffF0F2F5),
            borderRadius: BorderRadius.circular(20),),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(// اینجا می‌توانید از PlayerController دوم برای پخش استفاده کنید
              // یا فقط یک ویوفرم ساده نمایش دهید
              child: AudioFileWaveforms(size: const Size(double.infinity, 30),
                playerController: controller.reviewPlayerController,
                enableSeekGesture: true,
                waveformType: WaveformType.fitWidth,
                playerWaveStyle: const PlayerWaveStyle(
                  fixedWaveColor: Colors.grey,
                  liveWaveColor: Color(0xff969bff),
                  spacing: 4,),),),
          ],),),),

        const SizedBox(width: 10),

        // دکمه ارسال
        FloatingActionButton(mini: true,
          backgroundColor: primaryColor,
          elevation: 2,
          onPressed: () => controller.sendRecordedFile(),
          child: const Icon(
            Icons.send_rounded, color: Colors.white, size: 20,),),
      ],),);
  }

  void _showAttachmentSheet(BuildContext context,
      ChatScreenController controller,) {
    Get.bottomSheet(Container(height: 280,
      // ارتفاع بیشتر برای گزینه‌های جدید
      decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text("Share",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
        const SizedBox(height: 30),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _attachOption(
              Icons.image_rounded, "photo (Gallery)", Colors.purple, () =>
                controller.pickAndSendMedia(ImageSource.gallery),),
            _attachOption(Icons.camera_alt_rounded, "Camera", Colors.pink, () =>
                controller.pickAndSendMedia(ImageSource.camera),),
            // گزینه جدید ویدیو
            _attachOption(
              Icons.videocam_rounded, "Video", Colors.blue, () =>
                controller.pickAndSendMedia(
                  ImageSource.gallery, isVideo: true,),),
          ],),
      ],),),);
  }

  Widget _attachOption(IconData icon, String label, Color color,
      VoidCallback onTap,) {
    return GestureDetector(onTap: () {
      Get.back();
      onTap();
    },
      child: Column(children: [
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle,),
          child: Icon(icon, color: color, size: 26),),
        const SizedBox(height: 8),
        Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),),
      ],),);
  }

  // --- UI ضبط قفل شده (Locked Recording) ---
  Widget _buildLockedRecordingUI(bool isEmojiOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(children: [
        // انیمیشن چشمک زن
        const _BlinkingRedDot(), const SizedBox(width: 10),

        // تایمر
        Obx(() =>
            Text("${(controller.recordDuration.value ~/ 60).toString().padLeft(
                2, '0')}:${(controller.recordDuration.value % 60)
                .toString()
                .padLeft(2, '0')}", style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),),),

        // موج زنده
        Expanded(child: AudioWaveforms(enableGesture: false,
          size: const Size(double.infinity, 40),
          recorderController: controller.recorderController,
          waveStyle: const WaveStyle(waveColor: Colors.black54,
            extendWaveform: true,
            showMiddleLine: false,),),),

        // دکمه لغو (سطل آشغال)
        TextButton(onPressed: () => controller.cancelAndDeleteRecording(),
          child: const Text("Cancel", style: TextStyle(color: Colors.red)),),

        const SizedBox(width: 8),

        // دکمه توقف و رفتن به بازبینی (Stop -> Review)
        GestureDetector(onTap: () => controller.stopForReview(),
          child: CircleAvatar(radius: 22,
            backgroundColor: primaryColor,
            child: const Icon(Icons.stop_rounded, color: Colors.white),),),
      ],),);
  }

  // --- UI حالت عادی + هندل کردن جسچرها ---
  Widget _buildNormalOrHoldRecordingUI(BuildContext context, bool isEmojiOpen) {
    return Container(color: Colors.transparent,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Container(
            constraints: const BoxConstraints(minHeight: 50, maxHeight: 120),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),),
              ],),
            child: controller.isRecording.value
                ? _buildHoldingRecordingUI() // نمایش UI ضبط وقتی دکمه نگه داشته شده
                : _buildTextInputUI(
              context, isEmojiOpen,), // نمایش تکست فیلد عادی
          ),),

          const SizedBox(width: 8),

          // دکمه میکروفون / ارسال با Gesture های پیچیده
          GestureDetector(onTap: () {
            if (controller.showSendButton.value) {
              controller.sendMessage();
            }
          },
            onLongPressStart: (_) async {
              if (!controller.showSendButton.value) {
                await controller.startRecording();
              }
            },
            onLongPressEnd: (details) {
              // اگر قفل نشده بود و انگشت برداشته شد -> برو به بازبینی (یا ارسال مستقیم طبق سلیقه، اینجا طبق درخواست شما بازبینی می‌گذاریم)
              if (!controller.isRecordingLocked.value &&
                  controller.isRecording.value) {
                controller.stopForReview();
              }
            },
            onLongPressMoveUpdate: (details) {
              // تشخیص حرکت انگشت به سمت بالا برای قفل کردن
              // اگر افست منفی (به سمت بالا) بیشتر از یک حدی بود
              if (details.offsetFromOrigin.dy < -50) {
                controller.lockRecording();
              }
            },
            child: Obx(() {
              // انیمیشن تغییر آیکون و سایز
              final isRec = controller.isRecording.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRec ? 60 : 50,
                // بزرگ شدن موقع ضبط
                height: isRec ? 60 : 50,
                decoration: BoxDecoration(color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),),
                  ],),
                child: Icon(controller.showSendButton.value
                    ? Icons.send_rounded
                    : (controller.isRecordingLocked.value
                    ? Icons.stop_rounded
                    : Icons.mic_rounded), color: Colors.white, size: 24,),);
            }),),
        ],),);
  }

  Widget _buildTextInputUI(BuildContext context, bool isEmojiOpen) {
    return Column(mainAxisSize: MainAxisSize.min, children: [Obx(() {
      if (controller.isEditing.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Row(children: [
            const Icon(Icons.edit, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text("Edit message...", style: TextStyle(
              color: Colors.blue, fontWeight: FontWeight.bold,),),),
            IconButton(icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: controller.cancelEditing,),
          ],),);
      }
      return const SizedBox.shrink();
    }), Row(children: [
      IconButton(onPressed: () {
        _showAttachmentSheet(context, controller);
      }, icon: Icon(Icons.attach_file, color: Colors.black),),
      IconButton(icon: Icon(
        controller.showEmojiPicker.value ? Icons.keyboard : Icons
            .emoji_emotions_outlined, color: Colors.grey,),
        onPressed: () async {
          if (isEmojiOpen) {
            // بستن ایموجی، باز کردن کیبورد
            controller.showEmojiPicker.value = false;
            await Future.delayed(const Duration(milliseconds: 50));
            controller.focusNode.requestFocus();
          } else {
            // بستن کیبورد، باز کردن ایموجی
            controller.focusNode.unfocus();
            await Future.delayed(const Duration(milliseconds: 50));
            controller.showEmojiPicker.value = true;
          }
        },),
      Expanded(child: Directionality(textDirection: .ltr,
        child: TextField(controller: controller.textCtrl,
          onChanged: controller.onTextChanged,
          maxLines: null,
          decoration: const InputDecoration(hintText: "Message...",
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: 10, horizontal: 10,),),),),),
    ],),
    ],);
  }

  Widget _buildHoldingRecordingUI() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        const _BlinkingRedDot(),
        const SizedBox(width: 8),
        Obx(() =>
            Text("${(controller.recordDuration.value ~/ 60).toString().padLeft(
                2, '0')}:${(controller.recordDuration.value % 60)
                .toString()
                .padLeft(2, '0')}",
              style: const TextStyle(fontWeight: FontWeight.bold),),),
        const Spacer(),
        const Icon(Icons.lock_open_rounded, size: 16, color: Colors.grey),
        const Text("Swipe up to lock",
          style: TextStyle(color: Colors.grey, fontSize: 10),),
        const SizedBox(width: 20),
        // فضای خالی برای جلوگیری از تداخل با انگشت
      ],),);
  }
}

class _BlinkingRedDot extends StatefulWidget {
  const _BlinkingRedDot();

  @override
  State<_BlinkingRedDot> createState() => _BlinkingRedDotState();
}

class _BlinkingRedDotState extends State<_BlinkingRedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),)
      ..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animationController,
      child: const Icon(
          Icons.fiber_manual_record, color: Colors.red, size: 16),);
  }
}

class _VideoMessageBubble extends StatefulWidget {
  final String videoUrl;
  final int fileSize; // حجم فایل به بایت
  final bool isMe;

  const _VideoMessageBubble(
      {super.key, required this.videoUrl, required this.fileSize, required this.isMe,});

  @override
  State<_VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<_VideoMessageBubble> {
  bool isDownloaded = false;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? localPath;
  VideoPlayerController? _videoController;
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  int? _realFileSize;

  @override
  void initState() {
    super.initState();
    // اگر سایز از بیرون نیامده بود، خودمان محاسبه میکنیم
    _realFileSize = widget.fileSize > 0 ? widget.fileSize : null;
    if (_realFileSize == null) {
      _fetchSize();
    }
    _checkFileExists();
  }

  void _fetchSize() async {
    int? size = await getFileSizeFromUrl(widget.videoUrl);
    if (mounted && size != null) {
      setState(() {
        _realFileSize = size;
      });
    }
  }

  // بررسی اینکه آیا فایل قبلاً دانلود شده است؟
  Future<void> _checkFileExists() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // نام فایل یکتا بر اساس URL
      final fileName = "vid_${widget.videoUrl.hashCode}.mp4";
      final file = File("${dir.path}/$fileName");

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            isDownloaded = true;
            localPath = file.path;
            _initializePlayer(file);
          });
        }
      }
    } catch (e) {
      debugPrint("Check file error: $e");
    }
  }

  void _initializePlayer(File file) {
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  Future<void> _startDownload() async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    _cancelToken = CancelToken();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = "vid_${widget.videoUrl.hashCode}.mp4";
      final savePath = "${dir.path}/$fileName";

      await _dio.download(widget.videoUrl, savePath, cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (mounted) {
              setState(() {
                downloadProgress = received / total;
              });
            }
          }
        },);

      if (mounted) {
        setState(() {
          isDownloading = false;
          isDownloaded = true;
          localPath = savePath;
          _initializePlayer(File(savePath));
        });
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) {
        setState(() {
          isDownloading = false;
          downloadProgress = 0.0;
        });
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      isDownloading = false;
      downloadProgress = 0.0;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Get.width * 0.65;

    return Container(width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black12, borderRadius: BorderRadius.circular(12),),
      child: Stack(alignment: Alignment.center, children: [
        // 1. نمایش ویدیو (پیش‌نمایش)
        if (isDownloaded && _videoController != null &&
            _videoController!.value.isInitialized)ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),),),

        // 2. لایه تاریک
        Container(decoration: BoxDecoration(
          color: Colors.black38, borderRadius: BorderRadius.circular(12),),),

        // 3. کنترل‌ها
        if (isDownloading)
        // ... (پروگرس بار دانلود مثل قبل) ...
          GestureDetector(onTap: _cancelDownload,
            child: Stack(alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: downloadProgress, color: Colors.white,),
                const Icon(Icons.close, color: Colors.white),
              ],),) else
          if (isDownloaded)
          // --- حالت پخش و بزرگ‌نمایی ---
            GestureDetector(onTap: () {
              // رفتن به صفحه تمام صفحه
              Get.to(() =>
                  FullScreenVideoPage(url: widget.videoUrl,
                    file: localPath != null ? File(localPath!) : null,),);
            },
              child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(backgroundColor: Colors.black54,
                    radius: 25,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white,
                      size: 35,),),
                  const SizedBox(height: 8),
                  // نمایش حجم (حتی اگر دانلود شده باشد هم بد نیست دیده شود یا زمان ویدیو)
                  Text(
                    _realFileSize != null ? formatBytes(_realFileSize, 1) : "",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 10),),
                ],),) else
          // --- حالت دانلود نشده ---
            GestureDetector(onTap: _startDownload,
              child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: widget.isMe
                        ? Colors.white.withOpacity(0.3)
                        : const Color(0xff969bff).withOpacity(0.8),
                      shape: BoxShape.circle,),
                    child: const Icon(
                      Icons.arrow_downward, color: Colors.white, size: 28,),),
                  const SizedBox(height: 8),

                  // *** نمایش حجم فایل محاسبه شده ***
                  Container(padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4,),
                    decoration: BoxDecoration(color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),),
                    child: Text(
                      formatBytes(_realFileSize, 1), // استفاده از متغیر جدید
                      style: const TextStyle(color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,),),),
                ],),),
      ],),);
  }
}

String formatBytes(int? bytes, int decimals) {
  if (bytes == null || bytes <= 0) return "Calculating...";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (bytes > 0) ? (bytes
      .toString()
      .length - 1) ~/ 3 : 0;
  double size = bytes / 1.0;
  for (int j = 0; j < i; j++) {
    size = size / 1024;
  }
  return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
}

// گرفتن حجم فایل از طریق لینک بدون دانلود کامل (HEAD Request)
Future<int?> getFileSizeFromUrl(String url) async {
  try {
    final http.Response response = await http.head(Uri.parse(url));
    if (response.headers['content-length'] != null) {
      return int.parse(response.headers['content-length']!);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// فرمت زمان (مثلاً 02:15)
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}

class FullScreenVideoPage extends StatefulWidget {
  final String url;
  final File? file; // اگر فایل لوکال بود

  const FullScreenVideoPage({super.key, required this.url, this.file});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      _controller = VideoPlayerController.file(widget.file!);
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    }

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
    });

    // مخفی کردن کنترل‌ها بعد از 3 ثانیه
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, body: GestureDetector(onTap: () {
      setState(() => _showControls = !_showControls);
    },
      child: Stack(alignment: Alignment.center,
        children: [
          Center(child: _controller.value.isInitialized ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),) : const CircularProgressIndicator(
              color: Color(0xff969bff)),),

          // دکمه وسط صفحه (Play/Pause)
          if (_showControls && _controller.value.isInitialized)GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller
                    .play();
              });
            },
            child: Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54, shape: BoxShape.circle,),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white, size: 50,),),),

          // نوار پایین (تایم لاین)
          if (_showControls && _controller.value.isInitialized)Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5,),
              decoration: BoxDecoration(color: Colors.black54,
                borderRadius: BorderRadius.circular(10),),
              child: Row(children: [
                Text(formatDuration(_controller.value.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12,),),
                Expanded(child: VideoProgressIndicator(
                  _controller, allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  colors: const VideoProgressColors(playedColor: Color(
                      0xff969bff),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.grey,),),),
                Text(formatDuration(_controller.value.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12,),),
              ],),),),

          // دکمه بازگشت
          if (_showControls)Positioned(top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Get.back(),),),
        ],),),);
  }
}
