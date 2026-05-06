import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:zenrun/src/chat_service/message_model.dart';

class SocketService extends GetxService {
  IO.Socket? socket;

  // متغیرهای Reactive
  var isConnected = false.obs;
  var newMessageReceived = Rxn<MessageModel>();
  var typingStatus = Rxn<Map<String, dynamic>>(); // {senderId, isTyping}

  Future<SocketService> init() async {
    return this;
  }

  // اتصال به سوکت با آدرس و توکن
  void connect(String token) {
    // اگر قبلاً وصل شده، ریترن کن
    if (socket != null && socket!.connected) {
      print("Socket is already connected.");
      return;
    }

    // بستن سوکت قبلی اگر وجود دارد
    socket?.dispose();

    print("Connecting to Socket: http://217.182.171.221/ with Token: $token");

    socket = IO.io(
        "http://217.182.171.221/",
        IO.OptionBuilder()
            .setTransports(['websocket']) // اجبار به استفاده از وب‌سوکت
            .disableAutoConnect() // اتصال دستی
            .setAuth({'token': 'Bearer $token'}) // ارسال توکن در Auth (برای socket.ts شما)
            .setExtraHeaders({'token': 'Bearer $token'}) // ارسال توکن در هدر (محض اطمینان)
            .setReconnectionAttempts(5)
            .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ Socket Connected Successfully');
      isConnected.value = true;
    });

    socket!.onConnectError((data) {
      print('❌ Socket Connection Error: $data');
      isConnected.value = false;
    });

    socket!.onDisconnect((_) {
      print('⚠️ Socket Disconnected');
      isConnected.value = false;
    });

    // لیسنرها
    socket!.on('new_message', (data) {
      print("📩 New Private Message: $data");
      newMessageReceived.value = MessageModel.fromJson(data);
    });

    socket!.on('new_group_message', (data) {
      print("📩 New Group Message: $data");
      newMessageReceived.value = MessageModel.fromJson(data);
    });

    // --- اضافه شده: دریافت تاییدیه ارسال پیام خودمان ---
    socket!.on('message_sent', (data) {
      print("✅ Message Sent Confirmation: $data");
      // این خط باعث می‌شود پیام ارسالی خودمان هم به لیست اضافه شود
      newMessageReceived.value = MessageModel.fromJson(data);
    });

    socket!.on('user_typing', (data) => typingStatus.value = data);
  }

  // --- ارسال پیام ---
  void sendMessage(Map<String, dynamic> data) {
    if (socket?.connected == true) {
      socket?.emit('send_message', data);
    } else {
      print("⚠️ Cannot send message: Socket is disconnected.");
    }
  }

  void sendTyping(int receiverId, bool isTyping) {
    if (socket?.connected == true) {
      socket?.emit(isTyping ? 'typing_start' : 'typing_stop', {'receiverId': receiverId});
    }
  }

  void markSeen(int senderId) {
    if (socket?.connected == true) {
      socket?.emit('mark_seen', {'senderId': senderId});
    }
  }

  void deleteMessage(int messageId, int receiverId) {
    if (socket?.connected == true) {
      socket?.emit('delete_message', {'messageId': messageId, 'receiverId': receiverId});
    }
  }

  void disconnect() {
    socket?.disconnect();
  }
}