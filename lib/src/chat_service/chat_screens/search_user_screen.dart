import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../api_models_repo/models/profile_model.dart';
import '../chat_controller/search_user_controller.dart';
import '../colors.dart';

class SearchUserScreen extends StatelessWidget {
  const SearchUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchUserController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              // --- نوار جستجو ---
              _buildSearchBar(controller),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // --- لیست نتایج ---
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00A79B),
                      ),
                    );
                  }

                  // --- تغییر مهم: استفاده از متغیر observable ---
                  // اگر متن خالی است، صفحه اولیه را نشان بده
                  if (controller.searchText.value.isEmpty) {
                    return _buildInitialState();
                  }

                  // اگر متن پر است اما نتیجه‌ای نیست
                  if (controller.filteredUsers.isEmpty) {
                    return _buildEmptyState();
                  }

                  // 4. نمایش لیست نتایج
                  return ListView.separated(
                    itemCount: controller.filteredUsers.length,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (c, i) =>
                        const Divider(indent: 70, endIndent: 20, height: 1),
                    itemBuilder: (context, index) {
                      final user = controller.filteredUsers[index];
                      return _buildUserTile(user);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(SearchUserController controller) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 50,
            width: Get.width * .8,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: controller.textController,
              onChanged: (value) => controller.filterUsers(value),
              autofocus: true,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                hintText: "search (Name Or Username)",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_forward_ios_outlined, color: btn1),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[200]),
          const Gap(15),
          Text(
            "Name Or Username",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(ProfileModel user) {
    return ListTile(
      onTap: () {
        Get.toNamed(
          "/profileScreen",
          arguments: user,
          parameters: {"withBack": "true"},
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: user.image != null && user.image!.isNotEmpty
              ? FastCachedImage(url: user.image!, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey[100],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
        ),
      ),
      title: Text(
        user.username ?? "User",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        "${user.name ?? ''} ${user.family ?? ''}",
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const Gap(10),
          Text(
            "User not found",
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
