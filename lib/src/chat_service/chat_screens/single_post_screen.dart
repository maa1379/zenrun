// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:gereh/core/api_helper.dart';
// import 'package:gereh/models/post_model.dart';
// import 'package:gereh/controllers/social_controller.dart';
// import 'package:gereh/widgets/social_post_item.dart';
//
// class SinglePostController extends GetxController {
//   var isLoading = true.obs;
//   var post = Rxn<PostModel>();
//   String? postId;
//
//   @override
//   void onInit() {
//     super.onInit();
//     // دریافت ID از پارامترهای لینک (مثلا /post/:id)
//     postId = Get.parameters['id'];
//     if (postId != null) {
//       fetchPost(postId!);
//     }
//   }
//
//   Future<void> fetchPost(String id) async {
//     isLoading.value = true;
//     final res = await ApiHelper.post("Post.aspx", queryParams: {"id": id});
//
//     if (res.isSuccess && (res.data as List).isNotEmpty) {
//       post.value = PostModel.fromJson(res.data[0]);
//     }
//     isLoading.value = false;
//   }
// }
//
// class SinglePostScreen extends StatelessWidget {
//   const SinglePostScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // اطمینان از وجود SocialController چون PostItem به آن نیاز دارد
//     if (!Get.isRegistered<SocialController>()) {
//       Get.put(SocialController());
//     }
//
//     final controller = Get.put(SinglePostController());
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             // اگر صفحه‌ای در استک نبود (مستقیم با لینک باز شده)، به صفحه اصلی برو
//             if (Get.key.currentState?.canPop() ?? false) {
//               Get.back();
//             } else {
//               Get.offAllNamed("/main");
//             }
//           },
//         ),
//         title: const Text("مشاهده پست", style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       extendBodyBehindAppBar: true,
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator(color: Colors.white));
//         }
//
//         if (controller.post.value == null) {
//           return const Center(
//             child: Text(
//               "پست یافت نشد یا حذف شده است",
//               style: TextStyle(color: Colors.white),
//             ),
//           );
//         }
//
//         return Center(
//           child: PostItem(
//             post: controller.post.value!,
//             index: 99999, // یک ایندکس خاص برای جلوگیری از تداخل با لیست اصلی
//           ),
//         );
//       }),
//     );
//   }
// }