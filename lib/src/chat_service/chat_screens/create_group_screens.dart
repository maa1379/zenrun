import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';

import '../chat_controller/create_group_controller.dart';


// ==========================================
// صفحه اول: انتخاب اعضا
// ==========================================
class SelectMembersScreen extends StatelessWidget {
  const SelectMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateGroupController());
    const primaryColor = Color(0xff00A98E);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New group", style: TextStyle(color: Colors.black, fontSize: 16)),
            Text("Add members", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: .ltr,
        child: Column(
          children: [
            // سرچ باکس
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: controller.filterUsers,
                decoration: InputDecoration(
                  hintText: "search...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // لیست یوزرها
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.filteredUsers.isEmpty) {
                  return const Center(child: Text("User not found"));
                }
                return ListView.builder(
                  itemCount: controller.filteredUsers.length,
                  itemBuilder: (ctx, index) {
                    final user = controller.filteredUsers[index];
                    return Obx(() {
                      final isSelected = controller.selectedUserIds.contains(user.id);
                      return ListTile(
                        onTap: () => controller.toggleSelection(user.id),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: user.avatarUrl != null
                              ? FastCachedImageProvider(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(user.fullName.isNotEmpty ? user.fullName[0] : "?")
                              : null,
                        ),
                        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.username),
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: primaryColor,
                          shape: const CircleBorder(),
                          onChanged: (v) => controller.toggleSelection(user.id),
                        ),
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        if (controller.selectedUserIds.isEmpty) return const SizedBox.shrink();
        return FloatingActionButton(
          backgroundColor: primaryColor,
          child: const Icon(Icons.arrow_forward),
          onPressed: () {
            Get.to(() => GroupInfoScreen());
          },
        );
      }),
    );
  }
}

// ==========================================
// صفحه دوم: مشخصات گروه (نام و عکس)
// ==========================================
class GroupInfoScreen extends StatelessWidget {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  GroupInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CreateGroupController controller = Get.find();
    const primaryColor = Color(0xff00A98E);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group profile", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Directionality(
          textDirection: .ltr,
          child: Column(
            children: [
              GestureDetector(
                onTap: controller.pickImage,
                child: Obx(() => CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: controller.groupImage.value != null
                      ? FileImage(controller.groupImage.value!)
                      : null,
                  child: controller.groupImage.value == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                )),
              ),
              const SizedBox(height: 30),

              // نام گروه
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Group name (required)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // توضیحات
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Description (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // نمایش تعداد اعضا
              Text(
                "${controller.selectedUserIds.length} Selected member",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        return FloatingActionButton(
          backgroundColor: primaryColor,
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.check),
          onPressed: () {
            if (!controller.isLoading.value) {
              controller.finalizeGroupCreation(nameCtrl.text, descCtrl.text);
            }
          },
        );
      }),
    );
  }
}