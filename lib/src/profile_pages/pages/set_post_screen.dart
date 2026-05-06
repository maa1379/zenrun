import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

import '../../../core/widgets/image_picker_helper.dart';
import 'package:toln/toln.dart';

class SetPostScreen extends StatefulWidget {
  const SetPostScreen({super.key});

  @override
  State<SetPostScreen> createState() => _SetPostScreenState();
}

class _SetPostScreenState extends State<SetPostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsHelper.white,
      appBar: UiHelper.appBar("Uploading"),
      extendBodyBehindAppBar: true,
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            return ListView(
              children: [
                Gap(25),
                SizedBox(
                  height: 5.h,
                  width: 100.w,
                  child: Padding(
                    padding: EdgeInsets.only(left: 3.w, right: 7.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 15,
                      children: [
                        Gap(5),
                        Text(
                          "Reals".toLn(),
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Transform.scale(
                            scale: .9,
                            child: CupertinoSwitch(
                              activeTrackColor: ColorsHelper.btn1,
                              value: provider.isReels,
                              onChanged: (value) {
                                provider.isReels = value;
                                provider.update();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    spacing: 1,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildMediaItem(
                            index: 1,
                            isVideo: true,
                            file: provider.filePath1,
                            onTap: () async {
                              _showModal(
                                () async {
                                  provider.filePath1 =
                                      await ImagePickerHelper().selectCamera2();
                                  if (provider.filePath1 != null) {
                                    provider.fileChange1 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                                () async {
                                  provider.filePath1 = await ImagePickerHelper()
                                      .selectGallery2();
                                  if (provider.filePath1 != null) {
                                    provider.fileChange1 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                              );
                            },
                            disable: false,
                          ),
                          _buildMediaItem(
                            index: 1,
                            file: provider.filePath2,
                            isVideo: false,
                            onTap: () async {
                              _showModal(
                                () async {
                                  provider.filePath2 =
                                      await ImagePickerHelper().selectCamera2();
                                  if (provider.filePath2 != null) {
                                    provider.fileChange2 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                                () async {
                                  provider.filePath2 = await ImagePickerHelper()
                                      .selectGallery2();
                                  if (provider.filePath2 != null) {
                                    provider.fileChange2 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                              );
                            },
                            disable: false,
                          ),
                          _buildMediaItem(
                            index: 1,
                            file: provider.filePath3,
                            isVideo: false,
                            onTap: () async {
                              _showModal(
                                () async {
                                  provider.filePath3 =
                                      await ImagePickerHelper().selectCamera2();
                                  if (provider.filePath3 != null) {
                                    provider.fileChange2 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                                () async {
                                  provider.filePath3 = await ImagePickerHelper()
                                      .selectGallery2();
                                  if (provider.filePath3 != null) {
                                    provider.fileChange2 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                              );
                            },
                            disable: provider.isReels,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildMediaItem(
                            index: 1,
                            file: provider.filePath4,
                            isVideo: false,
                            onTap: () async {
                              _showModal(
                                () async {
                                  provider.filePath4 =
                                      await ImagePickerHelper().selectCamera2();
                                  if (provider.filePath4 != null) {
                                    provider.fileChange4 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                                () async {
                                  provider.filePath4 = await ImagePickerHelper()
                                      .selectGallery2();
                                  if (provider.filePath4 != null) {
                                    provider.fileChange4 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                              );
                            },
                            disable: provider.isReels,
                          ),
                          _buildMediaItem(
                            index: 1,
                            isVideo: false,
                            file: provider.filePath5,
                            onTap: () async {
                              _showModal(
                                () async {
                                  provider.filePath5 =
                                      await ImagePickerHelper().selectCamera2();
                                  if (provider.filePath5 != null) {
                                    provider.fileChange5 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                                () async {
                                  provider.filePath5 = await ImagePickerHelper()
                                      .selectGallery2();
                                  if (provider.filePath5 != null) {
                                    provider.fileChange5 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                              );
                            },
                            disable: provider.isReels,
                          ),
                          _buildMediaItem(
                            index: 1,
                            file: provider.filePath6,
                            isVideo: false,
                            onTap: () async {
                              _showModal(
                                () async {
                                  provider.filePath5 =
                                      await ImagePickerHelper().selectCamera2();
                                  if (provider.filePath5 != null) {
                                    provider.fileChange5 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                                () async {
                                  provider.filePath5 = await ImagePickerHelper()
                                      .selectGallery2();
                                  if (provider.filePath5 != null) {
                                    provider.fileChange5 = true;
                                    provider.update();
                                  }
                                  context.pop();
                                },
                              );
                            },
                            disable: provider.isReels,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap(25),
                Divider(endIndent: 20, indent: 20),
                Gap(25),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: UiHelper.textFormField(
                    provider.label,
                    false,
                    () {},
                    "Label",
                    (p0) {},
                    textAlign: TextAlign.start,
                  ),
                ),
                Gap(10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: UiHelper.textFormField(
                    provider.description,
                    false,
                    () {},
                    "Caption",
                    maxLine: 5,
                    (p0) {},
                    textAlign: TextAlign.start,
                  ),
                ),
                Gap(5.h),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: UiHelper.buttonMain2(
                    () {
                      // provider.setPost(context);
                    },
                    "Upload",
                    width: 85.w,
                    height: 5.5.h,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaItem({
    required int index,
    required Function() onTap,
    required bool isVideo,
    required bool disable,
    Uint8List? file,
  }) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: disable
              ? () {
                  ViewHelper.showWarningDialog(
                    context,
                    "You can only select one video or photo to reels.",
                  );
                }
              : onTap,
          child: SizedBox(
            height: 10.h,
            width: 20.w,
            child: Stack(
              children: [
                file != null
                    ? Center(
                        child: Container(
                          height: MediaQuery.sizeOf(context).height * .09,
                          width: MediaQuery.sizeOf(context).width * .19,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: UiHelper.borderRadius16,
                            border: Border.all(color: Colors.grey, width: 1),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: MemoryImage(file),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Container(
                          height: MediaQuery.sizeOf(context).height * .09,
                          width: MediaQuery.sizeOf(context).width * .19,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: UiHelper.borderRadius16,
                            border:
                                Border.all(color: ColorsHelper.btn2, width: 1),
                          ),
                          child: Center(
                            child: Icon(
                              isVideo
                                  ? Icons.ondemand_video
                                  : Icons.add_photo_alternate_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                Align(
                  alignment: Alignment.topRight,
                  child: UiHelper.iconBox(
                    Icon(
                      file == null ? Icons.add : Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                    () {},
                    color: ColorsHelper.btn1,
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModal(Function() onTap1, Function() onTap2) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SizedBox(
          height: 20.h,
          width: 100.w,
          child: ListView(
            children: [
              const Gap(25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onTap1,
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: ColorsHelper.btn2,
                          size: 30,
                        ),
                        Text(
                          "Camera".toLn(),
                          style: ThemeHelper.textStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onTap2,
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera_back,
                          color: ColorsHelper.btn2,
                          size: 30,
                        ),
                        Text(
                          "Gallery".toLn(),
                          style: ThemeHelper.textStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
