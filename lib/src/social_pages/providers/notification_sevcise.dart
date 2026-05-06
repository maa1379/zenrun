// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// List<AndroidNotificationAction> actionList = <AndroidNotificationAction>[
//   const AndroidNotificationAction("123", "Stop",
//       showsUserInterface: true, cancelNotification: false),
// ];
//
// class NotificationService {
//   final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   AndroidNotificationDetails channel = AndroidNotificationDetails(
//     'high_importance_channel',
//     'High Importance Notifications',
//     importance: Importance.max,
//     enableVibration: false,
//     channelShowBadge: true,
//     silent: true,
//     visibility: NotificationVisibility.public,
//     actions: actionList,
//     usesChronometer: true,
//     playSound: false,
//     priority: Priority.high,
//     ongoing: true,
//     autoCancel: false,
//     onlyAlertOnce: true,
//   );
//
//   AndroidNotificationDetails channel2 = const AndroidNotificationDetails(
//     'high_importance_channel',
//     'High Importance Notifications',
//     importance: Importance.max,
//     enableVibration: false,
//     channelShowBadge: true,
//     silent: false,
//     visibility: NotificationVisibility.public,
//     usesChronometer: false,
//     playSound: false,
//     priority: Priority.high,
//     ongoing: true,
//     autoCancel: false,
//     onlyAlertOnce: true,
//   );
//
//   Future<void> initNotification() async {
//     AndroidInitializationSettings initializationSettingsAndroid =
//         const AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     var initializationSettingsIOS = const DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       defaultPresentSound: false,
//       requestCriticalPermission: true,
//       requestProvisionalPermission: true,
//     );
//
//     var initializationSettings = InitializationSettings(
//         android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
//     await notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//       onDidReceiveNotificationResponse: (details) async {},
//     );
//   }
//
//   notificationDetails() {
//     return NotificationDetails(
//       android: channel,
//       iOS: const DarwinNotificationDetails(
//         presentSound: true,
//         presentBadge: true,
//         presentAlert: true,
//       ),
//     );
//   }
//
//   notificationDetails2() {
//     return NotificationDetails(
//       android: channel2,
//       iOS: const DarwinNotificationDetails(
//         presentSound: true,
//         presentBadge: true,
//         presentAlert: true,
//       ),
//     );
//   }
//
//   void showNotification() async {
//     await notificationsPlugin.show(
//         123, "Tornado Vpn", "", await notificationDetails());
//   }
//
//   void showNotification2(String title, String body) async {
//     await notificationsPlugin.show(
//         1, title, body, await notificationDetails2());
//   }
// }
//
// @pragma('vm:entry-point')
// void notificationTapBackground(
//     NotificationResponse notificationResponse) async {}

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendNotification(String deviceToken,String body) async {
  // URL جدید برای ارسال نوتیفیکیشن‌ها به Firebase HTTP v1 API
  final String fcmUrl = 'https://fcm.googleapis.com/v1/projects/zenrun-b3061/messages:send';

  // ساخت پیام
  final Map<String, dynamic> message = {
    "message": {
      "token": deviceToken,
      "notification": {
        "title": "ZenRun",
        "body": body
      },
    }
  };

  // ارسال درخواست HTTP به FCM API
  final response = await http.post(
    Uri.parse(fcmUrl),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode(message),
  );

  // بررسی پاسخ
  if (response.statusCode == 200) {
  } else {

  }
}
