import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/Costance.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  TextEditingController value = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsHelper.white,
      appBar: UiHelper.appBar("Send feedback"),
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: Column(
          children: [
            Gap(5.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: UiHelper.textFormField(
                value,
                false,
                    () {},
                "Feedback",
                maxLine: 5,
                    (p0) {},
                textAlign: TextAlign.start,
              ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: UiHelper.buttonMain2(() {}, "Send", width: 80.w,height: 5.5.h),
            ),
            Gap(5.h),
          ],
        )
      ),
    );
  }
}
