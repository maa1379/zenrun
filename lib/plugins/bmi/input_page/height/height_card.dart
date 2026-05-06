import 'package:sizer/sizer.dart';

import '../../../../core/widgets/Costance.dart';
import '../../input_page/card_title.dart';
import '../../input_page/height/height_picker.dart';
import '../../widget_utils.dart';
import 'package:flutter/material.dart';

class HeightCard extends StatelessWidget {
  final int height;
  final ValueChanged<int> onChanged;

  const HeightCard({super.key, this.height = 170, required this.onChanged});

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
          CardTitle("HEIGHT", subtitle: "(cm)"),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: screenAwareSize(8.0, context)),
              child: LayoutBuilder(builder: (context, constraints) {
                return HeightPicker(
                  widgetHeight: constraints.maxHeight,
                  minHeight: 100,
                  height: height,
                  onChange: (val) => onChanged(val),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
