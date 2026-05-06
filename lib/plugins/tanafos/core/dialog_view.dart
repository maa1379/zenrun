import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';

import '../choose_screen.dart';
import 'package:toln/toln.dart';

class DialogView {
  static showDanger(BuildContext context) {
    AwesomeDialog(
      context: context,
      width: MediaQuery.sizeOf(context).width,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(
        child: Text(
          "Are you sure you're breathing?".toLn(),
          style: TextStyle(color: Colors.black),
        ),
      ),
      titleTextStyle: TextStyle(
        color: Colors.red,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      title: "",
      btnOkOnPress: () {
        context.rAndRemoveUntilTo(SubmitResultScreen());
      },
      btnCancelOnPress: () {
        // context.pop();
      },
      btnOkColor: Colors.blue,
      btnOkText: "Yes",
      btnCancelColor: Colors.green,
      transitionAnimationDuration: Duration(milliseconds: 200),
      btnCancelText: "Back",
    ).show();
  }

  static showInfo(BuildContext context, String text, Function() onTap) {
    AwesomeDialog(
      context: context,
      width: MediaQuery.sizeOf(context).width,
      animType: AnimType.scale,
      isDense: true,
      dialogType: DialogType.info,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Center(
            child: Text(
              'Additional information'.toLn(),
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4),
          ...text.split("🔹").map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text.split("🔹").indexOf(item) == 0
                      ? SizedBox()
                      : Text('🔹'.toLn(), style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Expanded(child: Text(item, style: TextStyle(fontSize: 14))),
                ],
              ),
            );
          }),
        ],
      ),
      btnCancelColor: Colors.blue,
      transitionAnimationDuration: Duration(milliseconds: 200),
      btnCancelText: "OK",
      btnCancelOnPress: () {},
    ).show();
  }
}
