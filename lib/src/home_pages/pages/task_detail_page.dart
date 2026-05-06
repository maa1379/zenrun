import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/network/api_helper.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';
import 'package:zenrun/core/widgets/image_picker_helper.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/generated/assets.dart';
import 'package:zenrun/src/ai_pages/providers/ai_provider.dart';
import 'package:zenrun/src/api_models_repo/ai_service.dart';
import 'package:zenrun/src/api_models_repo/models/task_model.dart';
import 'package:zenrun/src/home_pages/pages/quiz_detail_page.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';
import 'package:zenrun/src/profile_pages/providers/shop_product_provider.dart';

import '../../social_pages/widgets/add_post_sheet.dart';
import '../../social_pages/widgets/audio_player.dart';
import '../providers/quiz_provider.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.data,
    required this.isComplete,
  });

  final TaskModel data;
  final bool isComplete;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TextEditingController godController = TextEditingController();
  YoutubePlayerController? youtubePlayerController;
  bool isNullOrEmpty(String? value) =>
      value == null || value.trim().isEmpty || value == 'null';

  @override
  void initState() {
    super.initState();
    _initYoutube();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      provider.clearMediaSelection();
      provider.initializeVideoPlayer(widget.data.videoUrlEn);
      context.read<ShopProductProvider>().getShopProductHistory();
    });
  }

  void _initYoutube() {
    if (!isNullOrEmpty(widget.data.youtubeFileUrl)) {
      final videoId = YoutubePlayer.convertUrlToId(widget.data.youtubeFileUrl!);
      if (videoId != null) {
        youtubePlayerController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );

        // Listener برای فهمیدن پایان ویدیو یوتیوب
        youtubePlayerController!.addListener(() {
          if (youtubePlayerController!.value.playerState == PlayerState.ended) {
            context.read<TaskProvider>().setMediaAsDone(true);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    youtubePlayerController?.dispose();
    godController.dispose();
    // Dispose Chewie is handled by PopScope in build
    super.dispose();
  }

  Future<void> openFileFromUrl(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("Error opening file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await context.read<TaskProvider>().disposeVideoPlayer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                _buildSliverAppBar(provider),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const Gap(20),

                        if (!isNullOrEmpty(widget.data.audioUrlEn)) ...[
                          _buildSectionTitle("Listen & Learn"),
                          _buildAudioBox(provider),
                          const Gap(20),
                        ],

                        if (!isNullOrEmpty(widget.data.videoUrlEn)) ...[
                          _buildSectionTitle("Watch carefully"),
                          _buildVideoBox(provider),
                          const Gap(20),
                        ],

                        if (!isNullOrEmpty(widget.data.youtubeFileUrl) && youtubePlayerController != null) ...[
                          _buildSectionTitle("YouTube Lesson"),
                          _buildYoutubeBox(),
                          const Gap(20),
                        ],

                        if (!isNullOrEmpty(widget.data.exampleUrl)) ...[
                          _buildSectionTitle("Example"),
                          _buildExampleBox(provider),
                          const Gap(20),
                        ],

                        _buildActionBoxes(provider),

                        const Gap(100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: _buildFloatingActions(context),
      ),
    );
  }

  Widget _buildSliverAppBar(TaskProvider provider) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: Colors.blue.shade900,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.data.title ?? "Task Detail",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (!isNullOrEmpty(widget.data.imageUrl))
              FastCachedImage(url: widget.data.imageUrl!, fit: BoxFit.cover)
            else
              Image.asset(Assets.imagesImg4, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.data.isInvite == false)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: widget.isComplete
                ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30)
                : IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: provider.isTaskActionDone ? Colors.greenAccent : Colors.white54,
                size: 30,
              ),
              onPressed: provider.isTaskActionDone ? () => _handleSubmit(provider) : null,
            ),
          )
      ],
    );
  }

  Widget _buildActionBoxes(TaskProvider provider) {
    return Column(
      children: [
        _buildMissionBox(provider),
        _buildFileBox(provider),
        _buildTakeBox(provider),
        _buildTextBox(provider),
        _buildInviteBox(provider),
      ],
    );
  }


  Widget _buildFloatingActions(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.smileUint8 == null && provider.videoUint8 == null) {
          return const SizedBox();
        }
        return FloatingActionButton.extended(
          onPressed: () {
            showCupertinoSheet(
              context: context,
              enableDrag: true,
              builder: (BuildContext context) {
                return AddPostSheet(
                  initialPhoto: provider.smileUint8,
                  initialVideo: provider.videoUint8,
                  isTask: true,
                );
              },
            );
          },
          label: const Text("Share to Social"),
          icon: const Icon(Icons.share),
          backgroundColor: ColorsHelper.btn2,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
      ),
    );
  }

  Widget _buildInfoCard() {
    if (isNullOrEmpty(widget.data.description) || widget.data.description == "0") return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        widget.data.description!.toLn(),
        style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.6),
      ),
    );
  }

  Widget _buildTextBox(TaskProvider provider) {
    if (widget.data.type != "Thanksgiving" && widget.data.type != "Expression of feeling") return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        children: [
          UiHelper.textFormField(godController, false, () {}, widget.data.title ?? "Write your thoughts...", (v) {}, maxLine: 4),
          const Gap(15),
          UiHelper.buttonMain2(() async {
            if (godController.text.isEmpty) return;
            ViewHelper.showLoading();
            final aiProvider = context.read<AiProvider>();
            bool status = (widget.data.type == "Expression of feeling")
                ? await aiProvider.aiSubmitTextsEmotion(godController.text)
                : await aiProvider.aiGodThanking(godController.text);
            ViewHelper.dismissLoading();
            if (status) {
              provider.setMediaAsDone(true);
              godController.clear();
              ViewHelper.showSuccessDialog(context, "Sent successfully");
            } else {
              ViewHelper.showErrorDialog(context);
            }
          }, "Submit Text", width: double.infinity, height: 50, color: Colors.blue.shade700),
        ],
      ),
    );
  }

  Widget _buildFileBox(TaskProvider provider) {
    if (isNullOrEmpty(widget.data.fileUrl)) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: UiHelper.buttonMain2(() async {
        if (!kIsWeb) {
          ViewHelper.showLoading();
          await openFileFromUrl(widget.data.fileUrl!, widget.data.fileUrl!.split("/").last);
          ViewHelper.dismissLoading();
          provider.setMediaAsDone(true);
        }
      }, "Download & View File", width: double.infinity, height: 50, color: Colors.teal),
    );
  }

  Widget _buildMissionBox(TaskProvider provider) {
    if (isNullOrEmpty(widget.data.mamoriyatUrl)) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: UiHelper.buttonMain2(() async {
        if (await canLaunchUrl(Uri.parse(widget.data.mamoriyatUrl!))) {
          await launchUrl(Uri.parse(widget.data.mamoriyatUrl!), mode: LaunchMode.externalApplication);
          provider.setMediaAsDone(true);
        }
      }, "Go to External Mission", width: double.infinity, height: 50, color: Colors.indigo),
    );
  }

  Widget _buildInviteBox(TaskProvider provider) {
    if (widget.data.isInvite == false) return const SizedBox();
    final inviteCount = provider.userTaskList.firstWhereOrNull((e) => e.taskId == widget.data.id)?.inviteCount ?? "0";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Goal: ${widget.data.inviteCount}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Invited: $inviteCount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const Gap(10),
          LinearProgressIndicator(value: (int.tryParse(inviteCount.toString()) ?? 0) / (widget.data.inviteCount ?? 1)),
          const Gap(20),
          UiHelper.buttonMain2(
                () async {
              final userEmail = await PrefHelpers.getUser();
              await SharePlus.instance.share(ShareParams(
                text:
                'Join ZenRun using my link and let\'s grow together!\nhttps://app.zenrun.ai/invite/?inviteEmail=$userEmail',
              ));
              // https://app.zenrun.ai/invite/?inviteEmail=amin@amin.com
              await provider.setUserTask(
                  widget.data.id.toString(), null, "false", "1", context);
              await provider.refreshUserTasks();

              final userTask = provider.userTaskList
                  .firstWhereOrNull((e) => e.taskId == widget.data.id);
              final requiredInvites = widget.data.inviteCount ?? 0;
              final actualInvites = userTask?.inviteCount ?? 0;

              if (actualInvites >= requiredInvites && requiredInvites > 0) {
                if (!widget.isComplete) {
                  ViewHelper.showSuccessDialog(context, "Invite task completed!");
                }
              }
            },
            "Invite Friends",
            width: double.infinity,
            height: 50,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTakeBox(TaskProvider provider) {
    if (widget.data.isMamoriyat == true) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: UiHelper.buttonMain2(() {
        _showMediaSourceModal(provider);
      }, "Upload Task Media", width: double.infinity, height: 50, color: ColorsHelper.btn2),
    );
  }

  Widget _buildExampleBox(TaskProvider provider) {
    if (provider.smileUrl != null) return Image.network(provider.smileUrl!, fit: BoxFit.cover);
    if (provider.videoUrl != null && provider.chewieController != null) return Chewie(controller: provider.chewieController!);
    if (widget.data.exampleUrl!.endsWith("jpg") || widget.data.exampleUrl!.endsWith("png")) return Image.network(widget.data.exampleUrl!, fit: BoxFit.cover);
    return const SizedBox();
  }
  Widget _buildYoutubeBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: YoutubePlayer(
        controller: youtubePlayerController!,
        showVideoProgressIndicator: true,
        progressColors: const ProgressBarColors(playedColor: Colors.red, handleColor: Colors.redAccent),
      ),
    );
  }

  Widget _buildVideoBox(TaskProvider provider) {
    return Container(
      height: 25.h,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: (provider.chewieController == null || !provider.chewieController!.videoPlayerController.value.isInitialized)
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Chewie(controller: provider.chewieController!),
      ),
    );
  }

  Widget _buildAudioBox(TaskProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: AudioPlayerWidget(
        audioUrl: widget.data.audioUrlEn!,
        imageUrl: widget.data.imageUrl ?? "",
        onTap: () => provider.setMediaAsDone(true),
      ),
    );
  }

  // --- Logic Helpers ---

  void _handleSubmit(TaskProvider provider) async {
    final shopProvider = context.read<ShopProductProvider>();
    final zenProduct = shopProvider.shopHistoryList.firstWhereOrNull((e) => !e.isExpire);
    final taskId = widget.data.id.toString();

    // لاجیک متصل شدن به کوییز
    Future<void> startQuiz() async {
      final quizProvider = context.read<QuizProvider>();
      await quizProvider.getAllQuizList();
      // پیدا کردن کوییزی کهtaskId آن برابر با تسک فعلی است
      final quiz = quizProvider.quizList.firstWhereOrNull((element) => element.taskId == widget.data.id);

      if (quiz != null) {
        quizProvider.answerList.clear();
        quizProvider.currentPage = 0;
        await quizProvider.startQuiz(quiz.id.toString());
        if (mounted) {
          // هدایت به صفحه کوییز
          await context.toCallBack(QuizDetailPage(quiz: quiz));
        }
      } else {
        if(mounted) ViewHelper.showErrorDialog(context, text: "No quiz found for this task");
      }
    }

    void submitTaskWithCoins(String r, String z, String s) async {
      final success = await provider.setUserTask(
        taskId,
        provider.smileUrl ?? provider.videoUrl ?? "",
        "false",
        provider.imageProcessed.length.toString(),
        context,
      );

      if (!success || !mounted) return;

      int multiplier(int? base, int value) => value * (base ?? 0);
      bool coinSuccess = false;

      // Logic calculation for multi-user tasks
      if (widget.data.twoUser == provider.imageProcessed.length) {
        coinSuccess = await provider.setTaskCoin(
          multiplier(widget.data.twoUser, widget.data.coin ?? 0).toString(),
          multiplier(widget.data.twoUser, int.tryParse(r) ?? 0).toString(),
          multiplier(widget.data.twoUser, int.tryParse(z) ?? 0).toString(),
          multiplier(widget.data.twoUser, int.tryParse(s) ?? 0).toString(),
        );
      } else if (widget.data.multiUser == provider.imageProcessed.length) {
        coinSuccess = await provider.setTaskCoin(
          multiplier(widget.data.multiUser, widget.data.coin ?? 0).toString(),
          multiplier(widget.data.multiUser, int.tryParse(r) ?? 0).toString(),
          multiplier(widget.data.multiUser, int.tryParse(z) ?? 0).toString(),
          multiplier(widget.data.multiUser, int.tryParse(s) ?? 0).toString(),
        );
      } else {
        coinSuccess = await provider.setTaskCoin(widget.data.coin.toString(), r, z, s);
      }

      if (coinSuccess && mounted) {
        // اگر تسک کوییز دارد، به کوییز برو، وگرنه تمام
        if (widget.data.isQuiz == true) {
          await startQuiz();
        } else {
          context.pop();
          ViewHelper.showSuccessDialog(context, "Successfully completed");
        }
      }
    }

    // بررسی محصولات خریداری شده برای افزایش کوین
    if (zenProduct != null) {
      DialogView.showWarning(context, "Use Magic Coins?", () {
        final multiplier = zenProduct.data;
        submitTaskWithCoins(
          (widget.data.rCoin! * (multiplier?.zaribRCoin ?? 1)).toString(),
          (widget.data.zCoin! * (multiplier?.zaribZCoin ?? 1)).toString(),
          (widget.data.sCoin! * (multiplier?.zaribSCoin ?? 1)).toString(),
        );
      });
    } else {
      DialogView.showWarning(
        context,
        "By doing this, you will earn (${widget.data.rCoin} R coins), (${widget.data.zCoin} Z coins) (${widget.data.sCoin} S coins) (${widget.data.coin} coins)",
            () => submitTaskWithCoins(
          widget.data.rCoin.toString(),
          widget.data.zCoin.toString(),
          widget.data.sCoin.toString(),
        ),
      );
    }
  }

  void _showMediaSourceModal(TaskProvider provider) {
    _showModal(
          () async {
        Navigator.pop(context);
        final file = await ImagePickerHelper().selectVideoFromCamera();
        if(file != null) {
          ViewHelper.showLoading();
          provider.videoUint8 = file;
          provider.videoUrl = await ApiHelper.uploaderWeb(file.bytes, file.type);
          ViewHelper.dismissLoading();
          provider.setMediaAsDone(true);
        }
      },
          () async {
        Navigator.pop(context);
        final file = await ImagePickerHelper().selectCamera2();
        if(file != null) {
          ViewHelper.showLoading();
          provider.smileUint8 = file;
          provider.smileUrl = await ApiHelper.uploaderWeb(file.bytes, file.type);
          ViewHelper.dismissLoading();
          provider.setMediaAsDone(true);
        }
      },
          () async {
        Navigator.pop(context);
        final file = await ImagePickerHelper().selectMedia();
        if(file != null) {
          ViewHelper.showLoading();
          if (file.type == "image") {
            provider.smileUint8 = SelectedMedia(bytes: file.bytes, type: file.name);
            provider.smileUrl = await ApiHelper.uploaderWeb(file.bytes, file.name);
          } else if (file.type == "video") {
            provider.videoUint8 = SelectedMedia(bytes: file.bytes, type: file.name);
            provider.videoUrl = await ApiHelper.uploaderWeb(file.bytes, file.name);
          }
          ViewHelper.dismissLoading();
          provider.setMediaAsDone(true);
        }
      },
    );
  }

  void _showModal(VoidCallback onTapVideo, VoidCallback onTapPhoto, VoidCallback onTapGallery) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SizedBox(
          height: 30.h,
          width: 100.w,
          child: Column(
            children: [
              Text("Upload Content".toLn(),
                  style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ModalButton(icon: Icons.photo_library, label: "Gallery", onTap: onTapGallery),
                  _ModalButton(icon: Icons.videocam, label: "Video", onTap: onTapVideo),
                  _ModalButton(icon: Icons.camera_alt, label: "Camera", onTap: onTapPhoto),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaContainer extends StatelessWidget {
  final Widget child;
  const _MediaContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: 35.h, minHeight: 20.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: UiHelper.shadow2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ModalButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          const Gap(8),
          Text(label.toLn(), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}