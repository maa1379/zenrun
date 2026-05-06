import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import '../chat_controller/call_controller.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CallController controller = Get.find<CallController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. لایه تصویر طرف مقابل (Remote)
          Positioned.fill(
            child: Obx(() {
              // فقط اگر ویدیو وصل شده نشان بده، وگرنه پروفایل را نشان بده
              if (controller.isRemoteVideoConnected.value) {
                return RTCVideoView(
                  controller.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                );
              }

              // حالت انتظار (نمایش نام و عکس)
              return Container(
                color: const Color(0xff121212),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 4),
                          image: controller.targetAvatar != null
                              ? DecorationImage(
                              image: FastCachedImageProvider(controller.targetAvatar!),
                              fit: BoxFit.cover
                          )
                              : null
                      ),
                      child: controller.targetAvatar == null
                          ? const Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 25),
                    Text(
                      controller.targetName ?? "Unknown",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      controller.callStatus.value,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              );
            }),
          ),

          // 2. لایه تصویر خودمان (Local)
          Obx(() {
            // در حالت تماس ورودی (قبل از جواب دادن) تصویر خودمان را نشان نمیدهیم
            if (controller.isIncoming.value) return const SizedBox.shrink();

            return Positioned(
              right: 20,
              top: 50,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(
                    controller.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            );
          }),

          // 3. دکمه‌ها
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
              child: Obx(() {
                // حالت A: تماس ورودی
                if (controller.isIncoming.value) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBtn(Icons.call_end, Colors.red, "Reject", controller.rejectCall),
                      _buildBtn(Icons.call, Colors.green, "Accept", controller.acceptCall),
                    ],
                  );
                }

                // حالت B: در حین مکالمه
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIcon(
                        controller.isMicMuted.value ? Icons.mic_off : Icons.mic,
                        controller.toggleMic
                    ),
                    _buildIcon(
                        controller.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
                        controller.toggleSpeaker
                    ),

                    // دکمه قطع
                    GestureDetector(
                      onTap: () => controller.endCall(),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 15)]
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),

                    _buildIcon(
                        controller.isCameraOff.value ? Icons.videocam_off : Icons.videocam,
                        controller.toggleCamera
                    ),
                    _buildIcon(Icons.cameraswitch, controller.switchCamera),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 15)]
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _buildIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}