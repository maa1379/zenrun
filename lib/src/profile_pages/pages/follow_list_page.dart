import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';

import '../../../core/widgets/Costance.dart';
import 'package:toln/toln.dart';

class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
        title: "Close Friends",
        body: ListView(
          children: [
            Gap(10),
            SizedBox(
              height: 5.h,
              width: 100.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 15,
                children: [
                  Gap(5),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ColorsHelper.btn1.withValues(alpha: 0.8),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    "shahin almasi".toLn(),
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  Spacer(),
                  UiHelper.buttonMain2(
                    () {
                      DialogView.showDanger(
                          context, "Do you want to remove?", "", () {});
                    },
                    "Remove",
                    width: 25.w,
                    height: 3.h,
                    fontSize: 14,
                  ),
                  Gap(10),
                ],
              ),
            ),
            Divider()
          ],
        ));
  }
}
