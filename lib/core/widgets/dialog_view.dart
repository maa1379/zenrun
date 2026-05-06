import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DialogView {
  static showDanger(
    BuildContext context,
    String body,
    String title,
    Function() onTap,
  ) {
    AwesomeDialog(
      context: context,
      width: 100.w,
      animType: AnimType.scale,
      dialogType: DialogType.warning,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(body, style: TextStyle(color: Colors.black,fontSize: 16),textAlign: TextAlign.center,),
        ),
      ),
      titleTextStyle: TextStyle(
        color: Colors.red,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      title: title,
      btnOkOnPress: () {
        onTap();
      },
      btnCancelOnPress: () {
        // context.pop();
      },
      btnOkColor: Colors.redAccent,
      btnOkText: "Yes",
      btnCancelColor: Colors.green,
      transitionAnimationDuration: Duration(milliseconds: 200),
      btnCancelText: "Back",
    ).show();
  }

  static showTypeDialog(
      BuildContext context,
      String body,
      DialogType type,
      Function() onTap,
      ) {
    AwesomeDialog(
      context: context,
      width: 100.w,
      animType: AnimType.scale,
      dialogType: type,
      body: Center(
        child: Center(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(body, style: TextStyle(color: Colors.black,fontSize: 16),textAlign: TextAlign.center,),
        )),
      ),
      btnOkOnPress: () {
        onTap();
      },
      btnCancelOnPress: () {
        // context.pop();
      },
      btnOkColor: Colors.green,
      btnOkText: "Ok",
      btnCancelColor: Colors.red,
      transitionAnimationDuration: Duration(milliseconds: 200),
      btnCancelText: "Back",
    ).show();
  }

  static showWarning(
    BuildContext context,
    String body,
    Function() onTap,
  ) {
    AwesomeDialog(
      context: context,
      width: 100.w,
      animType: AnimType.scale,
      dialogType: DialogType.question,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(body, style: TextStyle(color: Colors.black,fontSize: 16),textAlign: TextAlign.center,),
        ),
      ),
      titleTextStyle: TextStyle(
        color: Colors.red,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      title: "",
      btnOkOnPress: () {
        onTap();
      },
      btnOkColor: Colors.green,
      btnOkText: "Yes",
      btnCancelColor: Colors.green,
      transitionAnimationDuration: Duration(milliseconds: 200),
      btnCancelText: "Back",
    ).show();
  }
}
