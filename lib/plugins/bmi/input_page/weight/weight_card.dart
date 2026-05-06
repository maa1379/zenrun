import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/widgets/Costance.dart';
import '../../input_page/card_title.dart';
import '../../input_page/weight/weight_slider.dart';
import '../../widget_utils.dart' show screenAwareSize;

class WeightCard extends StatelessWidget {
  final int weight;
  final ValueChanged<int> onChanged;

  const WeightCard({super.key, this.weight = 70, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      width: 40.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UiHelper.borderRadius10,
        boxShadow: UiHelper.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CardTitle("WEIGHT", subtitle: "(kg)"),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenAwareSize(16.0, context),
                ),
                child: _drawSlider(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawSlider() {
    return WeightBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.isTight
              ? Container()
              : WeightSlider(
                  minValue: 20,
                  maxValue: 200,
                  value: weight,
                  onChanged: (val) => onChanged(val),
                  width: constraints.maxWidth,
                );
        },
      ),
    );
  }
}

class WeightBackground extends StatelessWidget {
  final Widget child;

  const WeightBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          height: screenAwareSize(250.0, context),
          decoration: BoxDecoration(
            gradient: UiHelper.gradient(),
            borderRadius: BorderRadius.circular(screenAwareSize(50.0, context)),
          ),
          child: child,
        ),
        // SvgPicture.asset(
        //   "assets/images/weight_arrow.svg",
        //   height: screenAwareSize(10.0, context),
        //   width: screenAwareSize(18.0, context),
        // ),
      ],
    );
  }
}
