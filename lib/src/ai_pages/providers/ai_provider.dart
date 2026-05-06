import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/network/DataState.dart';

import '../../api_models_repo/ai_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AiProvider extends ChangeNotifier {
  void update() => notifyListeners();
  ScrollController scrollController = ScrollController();
  bool loading = true;
  FocusNode focus = FocusNode();

  TextEditingController msg = TextEditingController();
  List<AiChatModel> chatList = [];

  Future<String> sendTextToAi(String text) async {
    final res = await AiService.instance.aiTextChat(
      msg: text,
      username: await PrefHelpers.getUser(),
      tone: "friendly",
    );
    if (res is DataSuccess) {
      return res.data ?? "";
    } else {
      return "No Response";
    }
  }

  Future<String> sendVoiceToAi(String url) async {
    final res = await AiService.instance.aiVoiceChat(
      audioUrl: url,
      username: await PrefHelpers.getUser(),
      tone: "friendly",
    );
    if (res is DataSuccess) {
      return res.data ?? "";
    } else {
      return "error";
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
          // duration: Duration(milliseconds: 300),
          // curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage(AiChatMode mode, String voiceUrl, bool isMe) async {
    String text = msg.text;
    msg.clear();
    chatList.add(
      AiChatModel(userName: await PrefHelpers.getUser() ?? "",msg: text, voiceUrl: voiceUrl, mode: mode, isMe: isMe),
    );
    scrollToBottom();
    loading = false;
    update();
    String aiMsg = (mode == AiChatMode.voiceChat)?await sendVoiceToAi(voiceUrl):await sendTextToAi(text);
    chatList.add(
      AiChatModel(userName: await PrefHelpers.getUser() ?? "",msg: aiMsg, voiceUrl: voiceUrl, mode: AiChatMode.textChat, isMe: false),
    );
    scrollToBottom();
    loading = true;
    update();
  }

  Future<void> saveChatList(List<AiChatModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString('chat_list', jsonString);
  }

  Future<List<AiChatModel>> loadChatList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('chat_list');
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => AiChatModel.fromJson(json)).toList();
  }

  Future<bool> aiSubmitTextsEmotion(String text) async {
    final res = await AiService.instance.aiSubmitTextsEmotion(
      msg: text,
      username: await PrefHelpers.getUser(),
    );
    if (res is DataSuccess) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> aiGodThanking(String text) async {
    final res = await AiService.instance.aiSubmitGodThanking(
      msg: text,
      username: await PrefHelpers.getUser(),
    );
    if (res is DataSuccess) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> aiSubmitReport1(String text) async {
    final res = await AiService.instance.aiSubmitReport1(
      msg: text,
      username: await PrefHelpers.getUser(),
    );
    if (res is DataSuccess) {
      return true;
    } else {
      return false;
    }
  }


}

class AiChatModel {
  String userName;
  String msg;
  String voiceUrl;
  bool isMe;
  AiChatMode mode;

  AiChatModel({
    required this.userName,
    required this.msg,
    required this.voiceUrl,
    required this.mode,
    required this.isMe,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'msg': msg,
    'voiceUrl': voiceUrl,
    'isMe': isMe,
    'mode': mode.name,
  };

  factory AiChatModel.fromJson(Map<String, dynamic> json) => AiChatModel(
    userName: json['userName'],
    msg: json['msg'],
    voiceUrl: json['voiceUrl'],
    isMe: json['isMe'],
    mode: AiChatMode.values.firstWhere((e) => e.name == json['mode']),
  );

}

enum AiChatMode { voiceChat, textChat }
