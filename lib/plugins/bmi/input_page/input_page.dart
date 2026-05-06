import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';

import '../input_page/height/height_card.dart';
import '../input_page/weight/weight_card.dart';
import '../model/gender.dart';
import '../widget_utils.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  InputPageState createState() {
    return InputPageState();
  }
}

class InputPageState extends State<InputPage> {
  Gender gender = Gender.other;
  int height = 170;
  int weight = 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelper.appBar("My BMI"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Gap(10),
          InputSummaryCard(gender: gender, weight: weight, height: height),
          Gap(5.h),
          Expanded(child: _buildCards(context)),
          Center(
            child: UiHelper.buttonMain2(
              ()async {
                ViewHelper.showLoading();
                await Future.delayed(Duration(seconds: 1));
                ViewHelper.dismissLoading();
                context.pop();
              },
              "Submit",
              width: 90.w,
            ),
          ),
          Gap(50),
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        WeightCard(
          weight: weight,
          onChanged: (val) => setState(() => weight = val),
        ),
        HeightCard(
          height: height,
          onChanged: (val) => setState(() => height = val),
        ),
      ],
    );
  }
}

class InputSummaryCard extends StatelessWidget {
  final Gender gender;
  final int height;
  final int weight;

  const InputSummaryCard({
    super.key,
    required this.gender,
    required this.height,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 90.w,
        height: screenAwareSize(32.0, context),
        decoration: BoxDecoration(
          color: ColorsHelper.btn1,
          borderRadius: UiHelper.borderRadius10,
          gradient: UiHelper.gradient(),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: _genderText()),
            _divider(),
            Expanded(child: _text("${weight}kg")),
            _divider(),
            Expanded(child: _text("${height}cm")),
          ],
        ),
      ),
    );
  }

  Widget _genderText() {
    String genderText = gender == Gender.other
        ? '-'
        : (gender == Gender.male ? 'Male' : 'Female');
    return _text(genderText);
  }

  Widget _text(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.black, fontSize: 15.0),
      textAlign: TextAlign.center,
    );
  }

  Widget _divider() {
    return Container(width: 1.0, color: Colors.white);
  }
}
