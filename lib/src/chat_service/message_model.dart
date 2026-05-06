
class ChatUser {
  final int id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final String? role; // <--- این فیلد جدید اضافه شد (admin / member)

  ChatUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      isOnline: json['isOnline'] ?? false,
      role: json['role'], // <--- دریافت نقش از جیسون
    );
  }

  // یک گتر کمکی
  bool get isAdmin => role == 'admin';
}

enum MessageStatus { sending, sent, failed }

class MessageModel {
  int? id;
  int? senderId;
  int? receiverId;
  int? groupId;
  String content;
  String type; // TEXT, IMAGE, VOICE, VIDEO
  String? fileUrl;
  int? fileSize;
  DateTime createdAt;
  bool isSeen;

  // --- فیلدهای جدید ---
  bool isPinned;
  bool isEdited;
  MessageStatus status; // وضعیت ارسال
  List<ReactionModel> reactions; // لیست ری‌اکشن‌ها
  MessageModel? parent; // ریپلای یا فوروارد

  MessageModel({
    this.id,
    this.senderId,
    this.receiverId,
    this.groupId,
    required this.content,
    required this.type,
    this.fileUrl,
    this.fileSize,
    required this.createdAt,
    this.isSeen = false,
    this.isPinned = false,
    this.isEdited = false,
    this.status = MessageStatus.sent, // پیش‌فرض: ارسال شده (برای پیام‌های دریافتی)
    this.reactions = const [],
    this.parent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      groupId: json['groupId'],
      content: json['content'] ?? "",
      type: json['type'] ?? "TEXT",
      fileUrl: json['fileUrl'],
      fileSize: json['fileSize'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isSeen: json['isSeen'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isEdited: json['isEdited'] ?? false,
      status: MessageStatus.sent,
      reactions: (json['reactions'] as List? ?? [])
          .map((e) => ReactionModel.fromJson(e))
          .toList(),
      parent: json['parent'] != null ? MessageModel.fromJson(json['parent']) : null,
    );
  }
}

class ReactionModel {
  int userId;
  String reaction; // ❤️, 👍, 😂

  ReactionModel({required this.userId, required this.reaction});

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      userId: json['userId'],
      reaction: json['reaction'],
    );
  }
}

class ConversationModel {
  int? partnerId;
  int? groupId;
  String title;
  String? avatarUrl;
  String lastMessage;
  String messageType;
  DateTime lastMessageTime;
  int unreadCount;
  bool isGroup;
  bool isPinned; // اضافه شد

  ConversationModel({
    this.partnerId,
    this.groupId,
    required this.title,
    this.avatarUrl,
    required this.lastMessage,
    required this.messageType,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isGroup,
    this.isPinned = false, // پیش‌فرض
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    bool isGrp = json['chatType'] == 'group';
    return ConversationModel(
      partnerId: isGrp ? null : json['remoteId'],
      groupId: isGrp ? json['remoteId'] : null,
      title: json['title'] ?? "ناشناس",
      avatarUrl: json['avatarUrl'],
      lastMessage: json['lastMessage'] ?? "",
      messageType: json['messageType'] ?? "TEXT",
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      isGroup: isGrp,
      isPinned: json['isPinned'] ?? false, // دریافت از جیسون
    );
  }
}
