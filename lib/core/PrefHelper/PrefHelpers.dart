import 'dart:async';
import 'dart:convert';

import 'package:zenrun/src/api_models_repo/models/product_model.dart';

import 'Prefs.dart';

class PrefHelpers {
  static Future<void> setUser(String user) async {
    await Prefs.set('user', user);
  }

  static Future<String?> getUser() async {
    return await (Prefs.get('user'));
  }

  static removeUser() async {
    return await Prefs.clear('user');
  }

  static Future<void> setToken(String Token) async {
    await Prefs.set('Token', Token);
  }

  static Future<String?> getToken() async {
    return await (Prefs.get('Token'));
  }

  static removeToken() async {
    return await Prefs.clear('Token');
  }

  static Future<void> setProfile(bool profile) async {
    await Prefs.setBool('profile', profile);
  }

  static Future<bool> getProfile() async {
    return await (Prefs.getBool('profile'));
  }

  static removeProfile() async {
    return await Prefs.clear('profile');
  }


  static Future<void> setCartModelDb(List<ProductModel> cart) async {
    List<String> jsonStringList = cart
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await Prefs.setList(jsonStringList, 'cart');
  }

  static Future getCartModelDb() async {
    return await Prefs.getList('cart');
  }

  static Future removeCartModelDb() async {
    return await Prefs.clearList('cart');
  }


  static Future<void> setChatToken(String ChatToken) async {
    await Prefs.set('ChatToken', ChatToken);
  }

  static Future<String?> getChatToken() async {
    return await (Prefs.get('ChatToken'));
  }

  static Future<dynamic> removeChatToken() async {
    return await Prefs.clear('ChatToken');
  }

  static Future<void> setVoiceSpeed(String VoiceSpeed) async {
    await Prefs.set('VoiceSpeed', VoiceSpeed);
  }

  static Future<String?> getVoiceSpeed() async {
    return await (Prefs.get('VoiceSpeed'));
  }

  static Future<dynamic> removeVoiceSpeed() async {
    return await Prefs.clear('ChatToken');
  }


  static Future<void> setFcm(String Fcm) async {
    await Prefs.set('Fcm', Fcm);
  }

  static Future<String?> getFcm() async {
    return await (Prefs.get('Fcm'));
  }

  static Future<dynamic> removeFcm() async {
    return await Prefs.clear('ChatToken');
  }

}
