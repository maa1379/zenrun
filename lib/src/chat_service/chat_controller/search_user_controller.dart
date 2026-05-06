import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './api_helper.dart';
import '../../api_models_repo/models/profile_model.dart';

class SearchUserController extends GetxController {
  final List<ProfileModel> _allUsers = [];
  var filteredUsers = <ProfileModel>[].obs;
  var isLoading = false.obs;

  // --- تغییر جدید: متغیر observable برای متن جستجو ---
  var searchText = ''.obs;

  final TextEditingController textController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    isLoading.value = true;
    try {
      final res = await ApiHelper.post("UserDetailNew.aspx", queryParams: {});
      if (res.isSuccess) {
        final List data = res.data;
        _allUsers.assignAll(data.map((e) => ProfileModel.fromJson(e)).toList());
        filteredUsers.clear();
      }
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void filterUsers(String query) {
    // --- تغییر جدید: آپدیت کردن متغیر observable ---
    searchText.value = query;

    if (query.isEmpty) {
      filteredUsers.clear();
    } else {
      final lowerQuery = query.toLowerCase();
      final result = _allUsers.where((user) {
        final name = (user.name ?? "").toLowerCase();
        final family = (user.family ?? "").toLowerCase();
        final username = (user.username ?? "").toLowerCase();
        final fullName = "$name $family";

        return name.contains(lowerQuery) ||
            family.contains(lowerQuery) ||
            fullName.contains(lowerQuery) ||
            username.contains(lowerQuery);
      }).toList();

      filteredUsers.assignAll(result);
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}