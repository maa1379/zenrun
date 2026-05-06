import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../message_model.dart';
import 'chat_global_controller.dart'; // مسیر فایل گلوبال کنترلر خودت رو ایمپورت کن

class CreateGroupController extends GetxController {
  final ChatGlobalController globalController = Get.find<ChatGlobalController>();

  // لیست کاربرانی که از سرور می‌گیریم
  var usersList = <ChatUser>[].obs;

  // لیست آی‌دی کاربرانی که تیک خورده‌اند
  var selectedUserIds = <int>[].obs;

  // برای جستجو
  var filteredUsers = <ChatUser>[].obs;

  // اطلاعات گروه
  var groupImage = Rxn<File>();

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    isLoading.value = true;
    // فراخوانی متد موجود در گلوبال کنترلر برای گرفتن لیست کاربران
    await globalController.fetchAllUsers();
    usersList.assignAll(globalController.allUsers);
    filteredUsers.assignAll(usersList);
    isLoading.value = false;
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.assignAll(usersList);
    } else {
      filteredUsers.assignAll(usersList.where((u) =>
      u.fullName.contains(query) || u.username.contains(query)).toList());
    }
  }

  void toggleSelection(int userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      groupImage.value = File(image.path);
    }
  }

  Future<void> finalizeGroupCreation(String groupName, String description) async {
    if (groupName.isEmpty) {
      Get.snackbar("خطا", "لطفا نام گروه را وارد کنید");
      return;
    }
    if (selectedUserIds.isEmpty) {
      Get.snackbar("خطا", "حداقل یک عضو باید انتخاب شود");
      return;
    }

    isLoading.value = true;

    bool success = await globalController.createGroup(
      groupName,
      description,
      groupImage.value,
      selectedUserIds,
    );

    isLoading.value = false;

    if (success) {
      Get.back(); // بستن صفحه اطلاعات گروه
      Get.back(); // بستن صفحه انتخاب اعضا
      Get.snackbar("موفق", "گروه با موفقیت ساخته شد");
    } else {
      Get.snackbar("خطا", "ساخت گروه با مشکل مواجه شد");
    }
  }
}