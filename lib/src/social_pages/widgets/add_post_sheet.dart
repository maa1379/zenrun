import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:video_player/video_player.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/follow_model.dart'; // Import added
import 'package:zenrun/src/api_models_repo/models/post_model.dart';
import 'package:zenrun/src/api_models_repo/models/tag_model.dart';

import '../../../core/widgets/Costance.dart';
import '../../../core/widgets/image_picker_helper.dart';
import '../../../core/widgets/video_thumbnail_helper.dart';
import '../../profile_pages/providers/profile_provider.dart';

class AddPostSheet extends StatefulWidget {
  final PostModel? postToEdit;
  final bool isTask;
  final SelectedMedia? initialPhoto;
  final SelectedMedia? initialVideo;

  const AddPostSheet({
    super.key,
    this.postToEdit,
    required this.isTask,
    this.initialPhoto,
    this.initialVideo,
  });

  @override
  State<AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends State<AddPostSheet> {
  VideoPlayerController? _videoPlayerController;
  bool get _isEditMode => widget.postToEdit != null;

  final List<String?> _imageUrls = List.generate(5, (_) => null);
  String? _videoUrl;
  bool _isInitializingVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() {
    final provider = context.read<ProfileProvider>();
    if (provider.profile == null) {
      provider.getProfile();
    }

    provider.imageFiles = List.generate(5, (_) => null);
    provider.videoFile = List.generate(1, (_) => null);

    if (_isEditMode) {
      final post = widget.postToEdit!;
      provider.description.text = post.description ?? '';
      provider.isReels = post.isReels ?? false;
      provider.selectedCircleId = post.circleId;
      provider.selectedCircleTitle = post.circleTitle;
      _populateMediaForEdit(post.mediaList);
    } else {
      provider.description.clear();
      provider.isReels = false;
      provider.selectedCircleId = null;
      provider.selectedCircleTitle = null;
      provider.tagParamsList.clear();

      if (widget.initialPhoto != null) {
        provider.imageFiles[0] = widget.initialPhoto;
      }
      if (widget.initialVideo != null) {
        _initializeVideoFromBytes(widget.initialVideo!);
      }
    }
    setState(() {});
  }

  void _populateMediaForEdit(List<String> mediaList) {
    _videoUrl = mediaList.firstWhereOrNull((url) {
      final extension = p.extension(url).toLowerCase();
      return ['.mp4', '.mov', '.avi', '.mkv'].contains(extension);
    });

    final images = mediaList.where((url) => url != _videoUrl).toList();
    for (int i = 0; i < images.length && i < 5; i++) {
      _imageUrls[i] = images[i];
    }

    if (_videoUrl != null) {
      _initializeVideoNetwork(_videoUrl!);
    }
    setState(() {});
  }

  Future<void> _initializeVideoNetwork(String url) async {
    await _disposeVideoController();
    setState(() => _isInitializingVideo = true);
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();
      if (mounted) setState(() => _isInitializingVideo = false);
    } catch (e) {
      debugPrint("Error loading network video: $e");
      if (mounted) setState(() => _isInitializingVideo = false);
    }
  }

  Future<void> _initializeVideoFromBytes(SelectedMedia videoBytes) async {
    final provider = context.read<ProfileProvider>();
    provider.videoFile[0] = videoBytes;
    _videoUrl = null;

    await _disposeVideoController();
    setState(() => _isInitializingVideo = true);

    try {
      final path = await getFilePathFromBytes(
          videoBytes.bytes, DateTime.now().toIso8601String());
      _videoPlayerController = VideoPlayerController.file(File(path));
      await _videoPlayerController!.initialize();
      if (mounted) setState(() => _isInitializingVideo = false);
    } catch (e) {
      debugPrint("Error initializing video bytes: $e");
      if (mounted) setState(() => _isInitializingVideo = false);
    }
    provider.update();
  }

  Future<void> _disposeVideoController() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            height: 90.h,
            margin: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildHandleBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(provider),
                        const Gap(20),
                        _buildModeSelector(provider),
                        const Gap(20),
                        _buildMediaSection(provider),
                        const Gap(20),
                        _buildCaptionField(provider),
                        const Gap(20),
                        _buildSettingsSection(provider),
                        const Gap(30),
                        _buildSubmitButton(provider),
                        Gap(5.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTopBar(ProfileProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isEditMode ? "Edit Content" : "New Creation",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close, color: Colors.black54),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ProfileProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildModeTab("Post", !provider.isReels, () {
            if (provider.isReels) {
              provider.isReels = false;
              provider.selectedCircleId = null;
              provider.selectedCircleTitle = null;
              provider.update();
              setState(() {});
            }
          }),
          _buildModeTab("Reels", provider.isReels, () {
            if (!provider.isReels) {
              provider.isReels = true;
              provider.imageFiles = List.generate(5, (_) => null);
              for (int i = 0; i < _imageUrls.length; i++) {
                _imageUrls[i] = null;
              }
              provider.selectedCircleId = provider.circleList
                  .firstWhereOrNull((e) => e.title?.toLowerCase() == "all")
                  ?.id
                  .toString();
              provider.selectedCircleTitle = provider.circleList
                  .firstWhereOrNull((e) => e.title?.toLowerCase() == "all")
                  ?.title
                  .toString();
              provider.update();
              setState(() {});
            }
          }),
        ],
      ),
    );
  }

  Widget _buildModeTab(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? UiHelper.shadow2 : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(ProfileProvider provider) {
    final width = MediaQuery.of(context).size.width - 40;
    final spacing = 8.0;
    final largeBoxSize = width * 0.65;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MediaSlot(
                width: largeBoxSize,
                height: largeBoxSize,
                isVideo: true,
                localFile: provider.videoFile.firstOrNull,
                networkUrl: _videoUrl,
                controller: _videoPlayerController,
                isInitializing: _isInitializingVideo,
                onTap: () => _pickVideo(0),
                onDelete: () {
                  setState(() {
                    provider.videoFile[0] = null;
                    _videoUrl = null;
                    _disposeVideoController();
                  });
                  provider.update();
                },
              ),
              SizedBox(width: spacing),
              if (!provider.isReels)
                Expanded(
                  child: Column(
                    children: [
                      _MediaSlot(
                        width: double.infinity,
                        height: (largeBoxSize - spacing) / 2,
                        isVideo: false,
                        localFile: provider.imageFiles[0],
                        networkUrl: _imageUrls[0],
                        onTap: () => _pickImage(0),
                        onDelete: () => _removeImage(0, provider),
                      ),
                      SizedBox(height: spacing),
                      _MediaSlot(
                        width: double.infinity,
                        height: (largeBoxSize - spacing) / 2,
                        isVideo: false,
                        localFile: provider.imageFiles[1],
                        networkUrl: _imageUrls[1],
                        onTap: () => _pickImage(1),
                        onDelete: () => _removeImage(1, provider),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!provider.isReels) ...[
            SizedBox(height: spacing),
            Row(
              children: [
                Expanded(
                  child: _MediaSlot(
                    width: double.infinity,
                    height: (width - (spacing * 2)) / 3,
                    isVideo: false,
                    localFile: provider.imageFiles[2],
                    networkUrl: _imageUrls[2],
                    onTap: () => _pickImage(2),
                    onDelete: () => _removeImage(2, provider),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _MediaSlot(
                    width: double.infinity,
                    height: (width - (spacing * 2)) / 3,
                    isVideo: false,
                    localFile: provider.imageFiles[3],
                    networkUrl: _imageUrls[3],
                    onTap: () => _pickImage(3),
                    onDelete: () => _removeImage(3, provider),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _MediaSlot(
                    width: double.infinity,
                    height: (width - (spacing * 2)) / 3,
                    isVideo: false,
                    localFile: provider.imageFiles[4],
                    networkUrl: _imageUrls[4],
                    onTap: () => _pickImage(4),
                    onDelete: () => _removeImage(4, provider),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaptionField(ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: provider.description,
        maxLines: 4,
        minLines: 2,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: "Write a caption...",
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[400]),
          counterText: "",
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ProfileProvider provider) {
    if (provider.isReels) return const SizedBox();

    return Column(
      children: [
        _buildSettingTile(
          icon: Icons.public,
          title: "Select Circle",
          subtitle: provider.selectedCircleTitle ?? "Choose visibility",
          onTap: () {
            _showCircleSelector(provider);
          },
        ),
        const Gap(10),
        _buildSettingTile(
          icon: Icons.person_add_alt_1,
          title: "Tag People",
          subtitle: provider.tagParamsList.isEmpty
              ? "0 people tagged"
              : "${provider.tagParamsList.length} people tagged",
          onTap: () async {
            // --- FIX: Calling the local method instead of provider ---
            final result = await _showTagSelectorDialog(
              context: context,
              availableTags: provider.followingList,
              initiallySelected: provider.tagParamsList,
            );
            if (result != null) {
              provider.tagParamsList = result;
              provider.update();
            }
          },
        ),
        if (provider.tagParamsList.isNotEmpty) ...[
          const Gap(10),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: provider.tagParamsList
                  .map((e) => Chip(
                label: Text(e.friendEmail,
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: ColorsHelper.btn1.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  provider.tagParamsList.remove(e);
                  provider.update();
                },
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ))
                  .toList(),
            ),
          )
        ],
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsHelper.btn1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ColorsHelper.btn1, size: 20),
            ),
            const Gap(15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ProfileProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _validateAndSubmit(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsHelper.btn2,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isEditMode ? "Update Post" : "Share Post",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _removeImage(int index, ProfileProvider provider) {
    setState(() {
      provider.imageFiles[index] = null;
      _imageUrls[index] = null;
    });
    provider.update();
  }

  Future<void> _pickImage(int index) async {
    final result = await _showMediaPicker(isVideo: false);
    if (result != null) {
      setState(() {
        context.read<ProfileProvider>().imageFiles[index] = result;
        _imageUrls[index] = null;
      });
      context.read<ProfileProvider>().update();
    }
  }

  Future<void> _pickVideo(int index) async {
    final result = await _showMediaPicker(isVideo: true);
    if (result != null) {
      await _initializeVideoFromBytes(result);
    }
  }

  void _showCircleSelector(ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shrinkWrap: true,
        itemCount: provider.circleList.length,
        separatorBuilder: (c, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final circle = provider.circleList[i];
          return ListTile(
            title: Text(circle.title ?? ""),
            trailing: provider.selectedCircleTitle == circle.title
                ? Icon(Icons.check, color: ColorsHelper.btn1)
                : null,
            onTap: () {
              provider.selectedCircleTitle = circle.title;
              provider.selectedCircleId = circle.id.toString();
              provider.update();
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  Future<SelectedMedia?> _showMediaPicker({required bool isVideo}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    return await showModalBottomSheet<SelectedMedia?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Source",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _sourceButton(Icons.camera_alt, "Camera", () async {
                  final result = isVideo
                      ? await ImagePickerHelper().selectVideoFromCamera()
                      : await ImagePickerHelper().selectCamera2();
                  if (mounted) Navigator.pop(context, result);
                }),
                _sourceButton(Icons.photo_library, "Gallery", () async {
                  final result = isVideo
                      ? await ImagePickerHelper().selectVideoFromGallery()
                      : await ImagePickerHelper().selectGallery2();
                  if (mounted) Navigator.pop(context, result);
                }),
              ],
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: ColorsHelper.btn2),
          ),
          const Gap(8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- NEW: Tag Selector Dialog Logic ---
  Future<List<TagParams>?> _showTagSelectorDialog({
    required BuildContext context,
    required List<FollowModel> availableTags,
    List<TagParams>? initiallySelected,
  }) async {
    final provider = context.read<ProfileProvider>();
    List<TagParams> selectedTags = List.from(initiallySelected ?? []);

    return await showDialog<List<TagParams>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Select Friends'.toLn()),
              content: SizedBox(
                height: 50.h,
                width: 95.w,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isSelected = selectedTags
                          .any((e) => e.friendEmail == tag.followEmail);
                      return ChoiceChip(
                        label: Text(
                          tag.followEmail ??
                              tag.profileModel?.username ??
                              "User",
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTags.add(TagParams(
                                friendEmail: tag.followEmail ?? "",
                                type: "social",
                                description: "social tag",
                                isRead: "false",
                                circleId:
                                provider.selectedCircleId.toString(),
                                taskId: "0",
                                date: DateTime.now(),
                                profileModel: tag.profileModel,
                              ));
                            } else {
                              selectedTags.removeWhere((e) =>
                              e.friendEmail == tag.followEmail);
                            }
                          });
                        },
                        selectedColor: ColorsHelper.btn2,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    child: Text("Close".toLn()),
                    onPressed: () => Navigator.pop(context)),
                TextButton(
                    child: Text("Submit".toLn()),
                    onPressed: () => Navigator.pop(context, selectedTags)),
              ],
            );
          },
        );
      },
    );
  }

  void _validateAndSubmit(ProfileProvider provider) async {
    final bool hasLocalMedia = provider.videoFile.firstOrNull != null ||
        provider.imageFiles.any((img) => img != null);
    final bool hasExistingMedia =
        _videoUrl != null || _imageUrls.any((url) => url != null);
    final bool hasMedia = hasLocalMedia || hasExistingMedia;

    if (provider.description.text.trim().isEmpty) {
      ViewHelper.showWarningDialog(context, "Please write a caption.".toLn());
      return;
    }

    if (!provider.isReels && provider.selectedCircleId == null) {
      ViewHelper.showWarningDialog(context, "Please select a circle.".toLn());
      return;
    }

    if (!hasMedia) {
      ViewHelper.showWarningDialog(
          context, "Please add at least one photo or video.".toLn());
      return;
    }
    context.pop();
    await provider.setPost(
      context,
      isTask: widget.isTask,
      isEditMode: _isEditMode,
      postId: widget.postToEdit?.id,
      existingImageUrls: _imageUrls,
      existingVideoUrl: _videoUrl,
    );
  }
}

class _MediaSlot extends StatelessWidget {
  final double width;
  final double height;
  final bool isVideo;
  final SelectedMedia? localFile;
  final String? networkUrl;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VideoPlayerController? controller;
  final bool isInitializing;

  const _MediaSlot({
    required this.width,
    required this.height,
    required this.isVideo,
    this.localFile,
    this.networkUrl,
    required this.onTap,
    required this.onDelete,
    this.controller,
    this.isInitializing = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasContent = localFile != null || networkUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: hasContent
              ? Border.all(color: Colors.transparent)
              : Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            if (hasContent)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildContent(),
              ),
            if (!hasContent)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isVideo
                        ? Icons.videocam_rounded
                        : Icons.add_photo_alternate_rounded,
                    color: Colors.grey[400],
                    size: width > 100 ? 32 : 24,
                  ),
                  if (width > 80) ...[
                    const Gap(4),
                    Text(
                      isVideo ? "Add Video" : "Add Photo",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            if (hasContent && isVideo && !isInitializing)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 24),
                ),
              ),
            if (hasContent)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isVideo) {
      if (isInitializing) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (controller != null && controller!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller!.value.size.width,
            height: controller!.value.size.height,
            child: VideoPlayer(controller!),
          ),
        );
      }
      return Container(color: Colors.black);
    } else {
      if (localFile != null) {
        return Image.memory(localFile!.bytes, fit: BoxFit.cover);
      } else if (networkUrl != null) {
        return Image.network(
          networkUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
        );
      }
    }
    return const SizedBox();
  }
}