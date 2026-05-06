import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../chat_controller/story_controller.dart';
import 'video_file_helper_stub.dart'
    if (dart.library.io) 'video_file_helper_io.dart';

class CreateStoryView extends StatefulWidget {
  const CreateStoryView({super.key});

  @override
  State<CreateStoryView> createState() => _CreateStoryViewState();
}

class _CreateStoryViewState extends State<CreateStoryView> {
  final StoryController controller = Get.find<StoryController>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  // تغییر: استفاده از XFile به جای File برای سازگاری با وب
  XFile? _pickedFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  /// انتخاب مدیا (عکس یا ویدیو)
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    XFile? file;

    if (isVideo) {
      file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
    } else {
      file = await _picker.pickImage(source: source);
    }

    if (file != null) {
      setState(() {
        _pickedFile = file;
        _isVideo = isVideo;
      });

      if (_isVideo) {
        // تغییر: نحوه لود کردن ویدیو در وب و موبایل متفاوت است
        if (kIsWeb) {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(_pickedFile!.path),
          );
        } else {
          _videoController = createFileVideoController(_pickedFile!.path);
        }

        _videoController!.initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        });
      }
    }
  }

  /// دکمه ارسال
  void _onSubmit() {
    if (_pickedFile == null) return;
    // تغییر: ارسال XFile به کنترلر
    controller.uploadStory(_pickedFile!, _captionController.text, _isVideo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildContent(),

          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),

          if (_pickedFile == null) _buildPickButtons(),

          if (_pickedFile != null) _buildBottomControls(),

          Obx(() {
            return controller.isUploading.value
                ? Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ویجت نمایش عکس یا ویدیو
  Widget _buildContent() {
    if (_pickedFile == null) {
      return Container(color: const Color(0xFF1a1a1a));
    }

    if (_isVideo &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (!_isVideo) {
      // تغییر: نحوه نمایش عکس در وب و موبایل
      if (kIsWeb) {
        return Image.network(
          _pickedFile!.path,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        return buildFileImage(_pickedFile!.path);
      }
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildPickButtons() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _optionButton(
            Icons.camera_alt,
            "Camera",
            () => _pickMedia(ImageSource.camera, false),
          ),
          _optionButton(
            Icons.image,
            "Gallery",
            () => _pickMedia(ImageSource.gallery, false),
          ),
          _optionButton(
            Icons.videocam,
            "Video",
            () => _pickMedia(ImageSource.gallery, true),
          ),
        ],
      ),
    );
  }

  Widget _optionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      left: 20,
      right: 20,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "Send",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
