import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/home_pages/pages/mission_page.dart';
import 'package:zenrun/src/home_pages/providers/main_provider.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';

import '../providers/quiz_provider.dart';
import 'music_player_screen.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  void initState() {
    Future.microtask(() {
      context.read<QuizProvider>().getAllQuizList();
      context.read<TaskProvider>().fetchAllData();
    });
    super.initState();
  }

  final tilePattern = [
    StairedGridTile(1.0, 10 / 2.8),
    StairedGridTile(1.0, 10 / 2.9),
    StairedGridTile(0.5, 1),
    StairedGridTile(0.5, 1),
  ];

  // متد کمکی برای پارس کردن رنگ‌ها به صورت امن
  Color _parseColor(String? hexColor, int fallbackIndex) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.primaries[fallbackIndex % Colors.primaries.length];
    }
    try {
      String cleanHex = hexColor.replaceAll('#', '').toLowerCase();
      if (cleanHex.length == 6) cleanHex = "ff$cleanHex";
      if (cleanHex.startsWith("0x")) cleanHex = cleanHex.substring(2);
      return Color(int.parse("0x$cleanHex"));
    } catch (e) {
      return Colors.primaries[fallbackIndex % Colors.primaries.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.state == ViewState.Loading) {
          return Center(child: UiHelper.showLoading());
        }

        if (provider.state == ViewState.Error) {
          return const Center(child: Text("Error loading data."));
        }

        if (provider.faslList.isEmpty) {
          return const Center(child: Text("No categories available.", style: TextStyle(color: Colors.grey)));
        }

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SizedBox(
            height: 100.h,
            width: 100.w,
            child: RefreshIndicator(
              color: ColorsHelper.btn2,
              onRefresh: () async {
                await provider.fetchAllData();
              },
              child: GridView.custom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                gridDelegate: SliverStairedGridDelegate(
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  tileBottomSpace: 12,
                  pattern: tilePattern,
                ),
                childrenDelegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = provider.faslList[index];
                    final tile = tilePattern[index % tilePattern.length];
                    final isHorizontal = tile.aspectRatio > 2;
                    final cardColor = _parseColor(item.color, index);

                    return _ExploreCategoryCard(
                      title: item.title ?? "Unknown",
                      imageUrl: item.image ?? "",
                      color: cardColor,
                      isHorizontal: isHorizontal,
                      isImageRight: index.isEven, // برای کارت‌های افقی، عکس یک در میان چپ و راست باشد
                      taskCount: item.taskList?.length ?? 0,
                      onTap: () {
                        final regex = RegExp(r'(موزیک|music)', caseSensitive: false);
                        if (regex.hasMatch(item.title ?? "")) {
                          context.to(
                            MusicPlayerScreen(
                              taskList: item.taskList ?? [],
                              title: item.title ?? "",
                              faslModel: item,
                            ),
                          );
                        } else {
                          context.to(
                            MissionPage(
                              taskList: item.taskList ?? [],
                              title: item.title ?? "",
                              faslModel: item,
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: provider.faslList.length,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
            ),
          ),
        );
      },
    );
  }
}

/// ویجت مجزا برای کارت‌های دسته‌بندی
class _ExploreCategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color color;
  final bool isHorizontal;
  final bool isImageRight;
  final int taskCount;
  final VoidCallback onTap;

  const _ExploreCategoryCard({
    required this.title,
    required this.imageUrl,
    required this.color,
    required this.isHorizontal,
    required this.isImageRight,
    required this.taskCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: isHorizontal ? _buildHorizontalLayout() : _buildVerticalLayout(),
        ),
      ),
    );
  }

  // لایوت برای کارت‌های مستطیلی افقی
  Widget _buildHorizontalLayout() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          if (!isImageRight) _buildImagePart(isRoundedRight: false),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$taskCount Missions",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (isImageRight) _buildImagePart(isRoundedRight: true),
        ],
      ),
    );
  }

  // بخش عکس برای کارت افقی
  Widget _buildImagePart({required bool isRoundedRight}) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(
        left: isRoundedRight ? Radius.zero : const Radius.circular(20),
        right: isRoundedRight ? const Radius.circular(20) : Radius.zero,
      ),
      child: SizedBox(
        width: 120,
        height: double.infinity,
        child: imageUrl.isNotEmpty
            ? FastCachedImage(
          url: imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        )
            : _buildErrorImage(),
      ),
    );
  }

  // لایوت برای کارت‌های مربعی (عکس به عنوان پس‌زمینه)
  Widget _buildVerticalLayout() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // تصویر پس‌زمینه
          imageUrl.isNotEmpty
              ? FastCachedImage(
            url: imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: color),
          )
              : Container(color: color),

          // گرادیان تیره روی عکس برای خوانایی بهتر متن
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // متن در پایین کارت
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$taskCount Tasks",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // زمانی که لینک عکس خراب است
  Widget _buildErrorImage() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
    );
  }
}