import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zenrun/src/chat_service/chat_screens/call_screen.dart';
import 'package:zenrun/src/chat_service/chat_screens/inbox_screen.dart';
import 'package:zenrun/src/chat_service/chat_screens/notification_screen.dart';
import 'package:zenrun/src/chat_service/chat_screens/profile_screen.dart';
import 'package:zenrun/src/chat_service/chat_screens/search_user_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

List<GetPage<dynamic>> getPages = [
  GetPage(name: "/inboxScreen", page: () => InboxScreen(),),
  GetPage(name: "/call_screen", page: () => CallScreen(),),
  GetPage(name: "/call_screen", page: () => CallScreen(),),
  GetPage(name: "/call_screen", page: () => CallScreen(),),
  GetPage(name: "/notificationScreen", page: () => NotificationScreen(),),
  GetPage(name: "/profileScreen", page: () => ProfileScreen(),parameters: {"withBack":"false"}),
  GetPage(name: "/searchUserScreen", page: () => SearchUserScreen(),),
];