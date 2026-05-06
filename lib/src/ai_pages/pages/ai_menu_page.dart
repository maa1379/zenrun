import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/generated/assets.dart';
import 'package:zenrun/src/ai_pages/pages/ai_text_page.dart';
import 'package:zenrun/src/ai_pages/providers/ai_provider.dart';

import '../../../core/widgets/custom_sacffold.dart';
import 'package:toln/toln.dart';

class AiMenuPage extends StatefulWidget {
  const AiMenuPage({super.key});

  @override
  State<AiMenuPage> createState() => _AiMenuPageState();
}

class _AiMenuPageState extends State<AiMenuPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "ZenRun Ai",
      body: ListView(
        children: [
          Gap(2.h),
          Container(
            height: 20.h,
            width: 100.w,
            margin: EdgeInsets.symmetric(horizontal: 5.w),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: ColorsHelper.btn2, width: 2),
              borderRadius: UiHelper.borderRadius16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(Assets.imagesChip, height: 12.h),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    Text(
                      "Talking with ai".toLn(),
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    UiHelper.iconBox(
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                      () {
                        context.to(AiTextPage());
                      },
                      color: ColorsHelper.btn2,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Gap(2.h),
          Container(
            height: 20.h,
            width: 100.w,
            margin: EdgeInsets.symmetric(horizontal: 5.w),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: ColorsHelper.btn2, width: 2),
              borderRadius: UiHelper.borderRadius16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(Assets.imagesEmotions, height: 14.h),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 20,
                    children: [
                      Text(
                        "Expression of emotions".toLn(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      UiHelper.iconBox(
                        Icon(Icons.arrow_forward_ios, color: Colors.white),
                        () {
                          context.to(
                            SendFeedbackPage(
                              title: "Expression of emotions",
                              answer: "How were your feelings today?",
                            ),
                          );
                        },
                        color: ColorsHelper.btn2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap(2.h),
          Container(
            height: 20.h,
            width: 100.w,
            margin: EdgeInsets.symmetric(horizontal: 5.w),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: ColorsHelper.btn2, width: 2),
              borderRadius: UiHelper.borderRadius16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(Assets.imagesPerformance, height: 10.h),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    Text(
                      "Daily performance".toLn(),
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    UiHelper.iconBox(
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                      () {
                        context.to(
                          SendFeedbackPage(
                            title: "Daily performance",
                            answer: "How was your performance today?",
                          ),
                        );
                      },
                      color: ColorsHelper.btn2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({
    super.key,
    required this.title,
    required this.answer,
  });

  final String title;
  final String answer;

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  TextEditingController value = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        value.clear();
      },
      child: Scaffold(
        backgroundColor: ColorsHelper.white,
        appBar: UiHelper.appBar(widget.title),
        body: SizedBox(
          height: 100.h,
          width: 100.w,
          child: Column(
            children: [
              Gap(5.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: UiHelper.textFormField(
                  value,
                  false,
                  () {},
                  widget.answer,
                  maxLine: 5,
                  (p0) {},
                  textAlign: TextAlign.start,
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: UiHelper.buttonMain2(
                  () async {
                    final provider = context.read<AiProvider>();
                    if (widget.title == "Daily performance") {
                      ViewHelper.showLoading();
                      await provider.aiSubmitReport1(value.text);
                      ViewHelper.dismissLoading();
                      context.pop();
                      ViewHelper.showSuccessDialog(
                          context, "Sent successfully");
                    } else {
                      ViewHelper.showLoading();
                      await provider.aiSubmitTextsEmotion(value.text);
                      ViewHelper.dismissLoading();
                      context.pop();
                      ViewHelper.showSuccessDialog(
                          context, "Sent successfully");
                    }
                  },
                  "Submit",
                  width: 94.w,
                  height: 5.h,
                ),
              ),
              Gap(5.h),
            ],
          ),
        ),
      ),
    );
  }
}
