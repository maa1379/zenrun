import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static Future set(String name, value) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    if (value == null) return instance.remove(name);
    return instance.setString(name, value);
  }

  static Future setBool(String name, value) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    if (value == null) return instance.remove(name);
    return instance.setBool(name, value);
  }

  static Future get(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getString(name);
  }

  static Future<bool> getBool(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getBool(name) ?? false;
  }

  static Future clear(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.remove(name);
  }



  static Future setList(List<String> value,String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.setStringList(name, value);
  }

  static Future getList(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.getStringList(name);
  }

  static Future clearList(String name) async {
    SharedPreferences instance = await SharedPreferences.getInstance();
    return instance.remove(name);
  }


}
