import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'colors.dart';

class FlushHelper {
  static void error(String text) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      snackPosition: SnackPosition.TOP,
      borderColor: Colors.red,
      borderWidth: 0.5,
      titleText: Container(),
      messageText: Directionality(
        textDirection: TextDirection.rtl, // اجبار به راست‌چین بودن کل محتوا
        child: Row(
          children: [
            BlinkingIcon(
              icon: Icons.error_outline,
              color: Colors.red,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "خطا",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(String text) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      snackPosition: SnackPosition.TOP,
      borderColor: btn1,
      borderWidth: 0.5,
      titleText: Container(),
      messageText: Directionality(
        textDirection: TextDirection.rtl, // اجبار به راست‌چین بودن کل محتوا
        child: Row(
          children: [
            BlinkingIcon(
              icon: Icons.check_circle_outline,
              color: btn1,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "موفق",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void warning(String text) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      snackPosition: SnackPosition.TOP,
      borderColor: Colors.lightBlue,
      borderWidth: 0.5,
      titleText: Container(),
      messageText: Directionality(
        textDirection: TextDirection.rtl, // اجبار به راست‌چین بودن کل محتوا
        child: Row(
          children: [
            BlinkingIcon(
              icon: Icons.warning_amber_outlined,
              color: Colors.lightBlue,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "اخطار",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlinkingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const BlinkingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
  });

  @override
  State<BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<BlinkingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.3,
      vsync: this,
    )..repeat(reverse: true); // تکرار انیمیشن به صورت رفت و برگشت

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}
