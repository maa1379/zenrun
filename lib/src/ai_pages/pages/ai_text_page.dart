import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:voice_note_kit/player/player_enums/player_enums.dart';
import 'package:voice_note_kit/recorder/voice_enums/voice_enums.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/extetions.dart';

import '../../../core/network/DataState.dart';
import '../../../core/network/api_helper.dart';
import '../../../core/widgets/Costance.dart';
import '../../../generated/assets.dart';
import '../../../plugins/player_widget.dart';
import '../../../plugins/recorder_widget.dart';
import '../providers/ai_provider.dart';
import 'package:toln/toln.dart';

class AiTextPage extends StatefulWidget {
  const AiTextPage({super.key});

  @override
  State<AiTextPage> createState() => _AiTextPageState();
}

class _AiTextPageState extends State<AiTextPage> {
  @override
  void initState() {
    Future.microtask(
      () async {
        context.read<AiProvider>().chatList.clear();
        context.read<AiProvider>().chatList =
            await context.read<AiProvider>().loadChatList();
        context.read<AiProvider>().scrollToBottom();
        context.read<AiProvider>().update();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, provider, child) {
        return PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            await provider.saveChatList(provider.chatList);
            context.read<AiProvider>().chatList.clear();
          },
          child: CustomScaffold(
            title: "Ai Chat",
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: _buildTextField(),
            ),
            body: ListView.builder(
              controller: provider.scrollController,
              itemCount: provider.chatList.length +
                  (provider.loading == false ? 1 : 0),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemBuilder: (context, index) {
                if (index < provider.chatList.length) {
                  final item = provider.chatList[index];
                  return Align(
                    alignment:
                        item.isMe ? Alignment.topRight : Alignment.centerLeft,
                    child: item.mode == AiChatMode.voiceChat
                        ? _buildAudioPlayer(
                            filepath: item.voiceUrl,
                            isNetwork: item.voiceUrl.startsWith("http"),
                            isMe: item.isMe,
                          )
                        : buildMeTextMsg(item.msg, item.isMe),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField() {
    return Consumer<AiProvider>(
      builder: (context, controller, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
          decoration: BoxDecoration(
            border: Border.all(width: 2, color: ColorsHelper.btn2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  maxLines: 5,
                  minLines: 1,
                  onChanged: (value) {
                    controller.msg.text = value;
                    controller.update();
                  },
                  keyboardType: TextInputType.multiline,
                  textAlign: TextAlign.start,
                  cursorColor: Colors.black,
                  focusNode: controller.focus,
                  controller: controller.msg,
                  style: ThemeHelper.textStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "Write message ...".toLn(),
                    hintStyle: ThemeHelper.textStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    fillColor: ColorsHelper.btn2,
                    filled: true,
                    labelStyle: ThemeHelper.textStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              const Gap(5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  (controller.msg.text.isEmpty)
                      ? _buildRecorder()
                      : GestureDetector(
                          onTap: () {
                            if (controller.msg.text.isNotEmpty) {
                              controller.sendMessage(
                                AiChatMode.textChat,
                                "",
                                true,
                              );
                            }
                          },
                          child: Image.asset(
                            Assets.imagesSend,
                            width: 35,
                            color: ColorsHelper.btn2,
                          ),
                        ),
                  const Gap(10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecorder() {
    return Consumer<AiProvider>(
      builder: (context, controller, child) {
        return VoiceRecorderWidget(
          iconSize: 30,
          showTimerText: true,
          showSwipeLeftToCancel: false,
          onRecorded: (file) async {
            final res = await ApiHelper.uploaderWeb(
              await file.readAsBytes(),
              "",
            );
            if (res is DataSuccess) {
              controller.sendMessage(
                AiChatMode.voiceChat,
                res.toString(),
                true,
              );
            }
          },
          onRecordedWeb: (url) {
            ViewHelper.showErrorDialog(
              context,
              text: "You cannot record on the web",
            );
          },
          // onRecordedWeb: (url) async {
          //   controller.sendFileMsgToList(userReceiver, url, "voice");
          //   final res = await ApiHelper.uploaderWebVoice(
          //     await blobUrlToBytes(url),
          //   );
          //   if (res is DataSuccess) {
          //     await controller.sendMessage(
          //       userReceiver,
          //       res.data.toString(),
          //       "voice",
          //     );
          //     controller.messageList.removeWhere(
          //       (element) => element.link == url,
          //     );
          //     controller.update();
          //   }
          // },
          style: VoiceUIStyle.classic,
          backgroundColor: Colors.transparent,
          cancelHintColor: Colors.red,
          iconColor: ColorsHelper.btn2,
          timerFontSize: 12,
        );
      },
    );
  }

  Widget buildMeTextMsg(String msg, bool isMe) {
    return Container(
      width: 58.w,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      margin: const EdgeInsets.only(right: 10, bottom: 10, left: 10),
      decoration: BoxDecoration(
        color: !isMe ? Color(0xffB388EB) : Color(0xffFF8C94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 5, left: 5),
        child: AutoSizeText(
          msg,
          minFontSize: 10,
          maxFontSize: 26,
          style: ThemeHelper.textStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer({
    required String filepath,
    required bool isNetwork,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 10, left: 10),
      child: AudioPlayerWidget(
        autoPlay: false,
        autoLoad: true,
        showSpeedControl: true,
        audioPath: filepath,
        audioType: !isNetwork && !kIsWeb
            ? AudioType.directFile
            : !isNetwork && kIsWeb
                ? AudioType.blobforWeb
                : AudioType.url,
        playerStyle: PlayerStyle.style5,
        textDirection: TextDirection.rtl,
        size: 28,
        progressBarHeight: 5,
        backgroundColor: !isMe ? Color(0xffB388EB) : Color(0xffFF8C94),
        progressBarColor: Colors.blue,
        progressBarBackgroundColor: Colors.black,
        iconColor: Colors.white,
        shapeType: PlayIconShapeType.circular,
        showProgressBar: true,
        showTimer: true,
        width: 58.w,
        audioSpeeds: const [0.5, 1.0, 1.5, 2.0, 3.0],
      ),
    );
  }
}
