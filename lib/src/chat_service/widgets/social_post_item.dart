import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:toln/toln.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/Costance.dart';
import '../../../core/widgets/dialog_view.dart';
import '../../../generated/assets.dart';
import '../../../services/get_profile_service.dart';
import '../chat_controller/api_helper.dart';
import '../../api_models_repo/models/post_model.dart';
import '../chat_controller/social_controller.dart';

class PostItem extends StatefulWidget {
  final PostModel post;
  final int index;
  final bool isReel;
  const PostItem({super.key, required this.post, required this.index, this.isReel = false});
  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> with SingleTickerProviderStateMixin {
  final SocialController controller = Get.find<SocialController>();

  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;


  bool _showHeart = false;
  bool _showMuteIcon = false;

  // برای مدیریت اسلایدربندی داخلی (عکس/ویدیو چندتایی)
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
    );

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showHeart = false);
          _heartAnimController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = controller.getMediaList(widget.post);
    final postId = widget.post.id ?? 0;
    final hasMultipleMedia = mediaList.length > 1;

    // 🌟 جایگزین شدن Scaffold با Container و تعیین ارتفاع داینامیک
    return Container(
      // اگر در ریلز بود تمام صفحه، اگر در لیست بود 75 درصد ارتفاع صفحه را بگیرد
      height: widget.isReel ? Get.height : Get.height * 0.75,
      color: Colors.black,
      child: GestureDetector(
        onDoubleTap: () {
          setState(() => _showHeart = true);
          _heartAnimController.forward();
          controller.toggleLike(postId);
        },
        onTap: () {
          final currentUrl = mediaList[_currentMediaIndex];
          if (controller.isVideo(currentUrl)) {
            controller.toggleMute();
            setState(() => _showMuteIcon = true);
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) setState(() => _showMuteIcon = false);
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediaList.length,
              onPageChanged: (index) {
                setState(() => _currentMediaIndex = index);
                controller.onHorizontalPageChanged(widget.index, index);
              },
              itemBuilder: (context, mIndex) {
                final url = mediaList[mIndex];
                if (controller.isVideo(url)) {
                  return _buildVideoPlayer(mIndex);
                }
                return FastCachedImage(
                  url: url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, progress) {
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.progressPercentage.value,
                        color: Colors.white24,
                      ),
                    );
                  },
                );
              },
            ),

            _buildGradientOverlay(),
            if (_showHeart) _buildHeartAnimation(),
            if (_showMuteIcon) _buildMuteOverlay(),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 16, right: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserInfo(),
                          const Gap(12),
                          _buildDescription(),
                          const Gap(12),
                          if (hasMultipleMedia)
                            _buildPageIndicator(mediaList.length),
                        ],
                      ),
                    ),

                    // بخش دکمه‌های عملیاتی (راست)
                    _buildRightSideBar(postId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ویجت جداگانه برای پلیر ویدیو
// ویجت جداگانه برای پلیر ویدیو
  Widget _buildVideoPlayer(int mIndex) {
    return Obx(() {
      // 🌟 تغییر کلیدی: اضافه شدن پیشوند reel یا feed به کلید ویدیو
      String prefix = widget.isReel ? "reel" : "feed";
      String videoKey = "${prefix}_${widget.index}_$mIndex";

      final vCtrl = controller.videoControllers[videoKey];

      if (vCtrl != null && vCtrl.controller.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: vCtrl.controller.value.size.width,
              height: vCtrl.controller.value.size.height,
              child: VideoPlayer(vCtrl.controller),
            ),
          ),
        );
      }

      // در زمان لودینگ اولیه
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A79B), strokeWidth: 2),
      );
    });
  }

  // اطلاعات کاربر (آواتار و نام)
  Widget _buildUserInfo() {
    return GestureDetector(
      onTap: () async{
        ApiHelper.showLoading();
        final user = await Get.find<GetProfileService>().getProfile(phone: widget.post.userEmail);
        ApiHelper.dismissLoading();
        Get.toNamed(
          "/profileScreen",
          arguments: user,
          parameters: {"withBack": "true"},
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2), // حاشیه سفید دور عکس
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: FastCachedImageProvider(
                widget.post.userImage ?? "",
              ),
            ),
          ),
          const Gap(10),
          Text(
            widget.post.userName ?? "User",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))],
            ),
          ),
          // دکمه فالو (اختیاری)
          // const Gap(10),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.white),
          //     borderRadius: BorderRadius.circular(6),
          //   ),
          //   child: const Text("Follow", style: TextStyle(color: Colors.white, fontSize: 10)),
          // )
        ],
      ),
    );
  }

  // توضیحات پست
  Widget _buildDescription() {
    return Text(
      widget.post.description ?? "",
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.3,
        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
      ),
      textDirection: TextDirection.rtl,
    );
  }

  // نشانگر صفحات (Dots)
  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final bool isActive = index == _currentMediaIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 16 : 6, // Active dot is wider
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00A79B) : Colors.white54,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  // نوار دکمه‌های سمت راست
  Widget _buildRightSideBar(int postId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // لایک
        Obx(() {
          final isLiked = controller.isLikedMap[postId]?.value ?? false;
          final count = controller.likeCounts[postId]?.value ?? 0;
          return _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.white,
            label: count.toString(),
            onTap: () => controller.toggleLike(postId),
          );
        }),
        const Gap(20),

        // کامنت
        Obx(() {
          final count = controller.commentCounts[postId]?.value ?? 0;
          return _ActionButton(
            icon: Icons.chat_bubble_rounded, // آیکون توپر مدرن‌تر
            color: Colors.white,
            label: count.toString(),
            onTap: () => controller.showCommentModal(postId),
            asset: Assets.imagesBlogging,
          );
        }),
        const Gap(20),

        // اشتراک گذاری
        _ActionButton(
          icon: Icons.share_rounded,
          color: Colors.white,
          label: "",
          asset: Assets.imagesSend,
          onTap: () => controller.shareLink(widget.post),
        ),

        // دکمه ارسال سکه (Coin)
        _ActionButton(
          icon: Icons.monetization_on, // آیکون جایگزین در صورت نبود عکس
          asset: Assets.imagesCoin,
          color: Colors.white,
          label: widget.post.Amount?.toString() ?? "0",
          onTap: () => _showCoinToPostDialog(context, widget.post),
        ),
        const Gap(20),

        // دکمه گزارش (Report)
        _ActionButton(
          icon: Icons.report_gmailerrorred_outlined,
          color: Colors.white,
          label: "Report",
          onTap: () {
            DialogView.showDanger(
              context,
              "Report this post?",
              "",
                  () {},
            );
          },
        ),

        const Gap(40), // فاصله از پایین برای اینکه دکمه‌ها خیلی پایین نباشند
      ],
    );
  }


  void _showCoinToPostDialog(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // برای اینکه گوشه‌های گرد به خوبی دیده شوند
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Send Coin to Post",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              const Gap(20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextFormField(
                  // توجه: این تکست‌کنترلر باید در SocialController ساخته شود
                  controller: controller.coinToPostAmount,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "Amount".toLn(),
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                    filled: true,
                    fillColor: ColorsHelper.btn1.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const Gap(20),
              UiHelper.buttonMain2(
                    () {
                  Navigator.pop(ctx);
                  // توجه: این متد باید در SocialController ساخته شود
                  controller.setCoinToPost(post.id.toString());
                },
                "Send",
                width: MediaQuery.of(context).size.width * 0.9,
                height: 45, // مقدار ثابت پیکسل جایگزین 4.5.h شد
                fontSize: 16,
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() => Positioned.fill(
    child: IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.6, 1.0],
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black87, // تیره‌تر و نرم‌تر در پایین
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHeartAnimation() => Center(
    child: ScaleTransition(
      scale: _heartScale,
      child: const Icon(
        Icons.favorite,
        color: Colors.white, // رنگ قلب سفید با شفافیت یا قرمز، سلیقه‌ای
        size: 100,
        shadows: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
    ),
  );

  Widget _buildMuteOverlay() => Center(
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(50),
          backgroundBlendMode: BlendMode.darken
      ),
      child: Obx(
            () => Icon(
          controller.isMuted.value ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.asset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            // یک پس زمینه بسیار محو برای دیده شدن روی تصاویر سفید
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                ]
            ),
            child: asset != null?Image.asset(asset ?? "",height: 26,color: Colors.white,):Icon(icon, color: color, size: 30),
          ),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 3)]
            ),
          ),
        ],
      ),
    );
  }
}