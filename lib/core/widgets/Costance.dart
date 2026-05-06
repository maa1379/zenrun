import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import '../../generated/assets.dart';
import '../flushbar/flushbar.dart';

class ColorsHelper {
  static const Color black = Color(0xff000000);
  static const Color red = Color(0xffF03F34);
  static const Color blue = Color(0xff0c1476);
  static const Color white = Color(0xffFFF8F5);
  static const Color gray1 = Color(0xff616064);
  static const Color textColor1 = Color(0xffF6F1FB);
  static const Color btn1 = Color(0xff969bff);
  static const Color btn2 = Color(0xffA78BFA);
  static final Color randomColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];
}

class ThemeHelper {
  static ThemeData themeData() {
    return ThemeData(
      // fontFamily: "Yekan",
      brightness: Brightness.light,
      scaffoldBackgroundColor: ColorsHelper.white,
      useMaterial3: true,
    );
  }

  static TextStyle textStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      color: color ?? ColorsHelper.black,
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }
}

class UiHelper {
  static List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.6),
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.2),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> shadow3 = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.3),
      blurRadius: 15,
      spreadRadius: 3,
    ),
  ];

  static List<BoxShadow> shadow4 = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.2),
      blurRadius: 5,
      spreadRadius: 2,
    ),
  ];

  static BorderRadius borderRadius50 = BorderRadius.circular(50);
  static BorderRadius borderRadius25 = BorderRadius.circular(25);
  static BorderRadius borderRadius16 = BorderRadius.circular(16);
  static BorderRadius borderRadius10 = BorderRadius.circular(10);
  static BorderRadius borderRadius6 = BorderRadius.circular(6);

  static Widget showLoading() {
    return Center(child: Lottie.asset(Assets.animAnimLoading, width: 150));
  }

  static AppBar appBar(
      String title,
      {Widget? action,Widget? leading,}
      ) => AppBar(
    backgroundColor: Colors.grey.shade100,
    elevation: 0,
    centerTitle: true,
    leadingWidth: leading == null?null:100,
    leading: leading,
    actions: [
      action ?? SizedBox(),
      Gap(10),
    ],
    title: Text(
      title,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500,fontSize: 18),
    ),
  );

  static Widget textFormField(
    TextEditingController textEditingController,
    bool obscureText,
    Function() onTap,
    String labelText,
    Function(String) onChange, {
    int? maxLen,
    Color? borderColor,
    int maxLine = 1,
    bool? enabled,
    String? errorText,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? textInputType,
    TextAlign? textAlign,
  }) {
    return TextFormField(
      inputFormatters: inputFormatters ?? [],
      maxLines: maxLine,
      enabled: enabled ?? true,
      maxLength: maxLen,
      keyboardType: textInputType ?? TextInputType.multiline,
      onChanged: onChange,
      controller: textEditingController,
      cursorColor: ColorsHelper.black,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      obscureText: obscureText,
      onTap: onTap,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textAlign: textAlign ?? TextAlign.center,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        fillColor: enabled == false ? Colors.grey.shade300 : ColorsHelper.white,
        filled: true,
        counterText: maxLen == null ? "" : null,
        counterStyle: const TextStyle(fontSize: 12),
        errorText: errorText,
        errorStyle: const TextStyle(color: ColorsHelper.red, fontSize: 12),
        isDense: true,
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.black,width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.btn2,width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.btn2,width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorsHelper.red,width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: ColorsHelper.black,
        ),
        hintText: labelText,
      ),
    );
  }

  static Widget textFormField3(
    TextEditingController textEditingController,
    bool obscureText,
    Function() onTap,
    String labelText,
    Function(String) onChange, {
    int? maxLen,
    Color? borderColor,
    int maxLine = 1,
    bool? enabled,
    String? errorText,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? textInputType,
    TextAlign? textAlign,
  }) {
    return TextFormField(
      inputFormatters: inputFormatters ?? [],
      maxLines: maxLine,
      enabled: enabled ?? true,
      maxLength: maxLen,
      keyboardType: textInputType ?? TextInputType.multiline,
      onChanged: onChange,
      controller: textEditingController,
      cursorColor: ColorsHelper.black,
      style: const TextStyle(color: Colors.black, fontSize: 20),
      obscureText: obscureText,
      onTap: onTap,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textAlign: textAlign ?? TextAlign.center,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        fillColor:
            enabled == false
                ? Colors.grey.withOpacity(0.3)
                : ColorsHelper.white,
        filled: enabled == false ? true : false,
        counterText: maxLen == null ? "" : null,
        counterStyle: const TextStyle(fontSize: 12),
        errorText: errorText,
        errorStyle: const TextStyle(color: ColorsHelper.red, fontSize: 12),
        isDense: true,
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.black),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.black),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.black),
          borderRadius: BorderRadius.circular(16),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorsHelper.red),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18.sp,
          color: ColorsHelper.black,
        ),
        labelText: labelText,
      ),
    );
  }

  static Widget textFormField2(
    TextEditingController textEditingController,
    bool obscureText,
    Function() onTap,
    String labelText,
    Function(String) onChange, {
    int? maxLen,
    Color? borderColor,
    int maxLine = 1,
    bool? enabled,
    String? errorText,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? textInputType,
    TextAlign? textAlign,
  }) {
    return TextFormField(
      inputFormatters: inputFormatters ?? [],
      maxLines: maxLine,
      enabled: enabled ?? true,
      maxLength: maxLen,
      keyboardType: textInputType ?? TextInputType.multiline,
      onChanged: onChange,
      controller: textEditingController,
      cursorColor: ColorsHelper.black,
      style: const TextStyle(color: Colors.black, fontSize: 20),
      obscureText: obscureText,
      onTap: onTap,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textAlign: textAlign ?? TextAlign.center,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        fillColor: ColorsHelper.white,
        filled: true,
        counterText: maxLen == null ? "" : null,
        counterStyle: const TextStyle(fontSize: 12),
        errorText: errorText,
        errorStyle: const TextStyle(color: ColorsHelper.red, fontSize: 12),
        isDense: true,
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.black),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.blue),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? ColorsHelper.blue),
          borderRadius: BorderRadius.circular(16),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorsHelper.red),
        ),
        hintStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: ColorsHelper.gray1,
        ),
        hintText: labelText,
      ),
    );
  }

  static Widget iconBox(
    Widget child,
    Function() onTap, {
    Color? color,
    double? height,
    double? width,
  }) {
    return Container(
      height: height ?? 6.h,
      width: width ?? 13.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.white,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(360),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }

  static Widget buttonMain(
    Function() onTap,
    Size size,
    String nameButton, {
    Color? color,
    Color? textColor,
    double? width,
    double? height,
    double? fontSize,
    double? radius,
    double? padding,
    Widget? icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding ?? size.width * .02),
      child: Container(
        width: width ?? size.width * 8,
        height: height ?? size.height * .05,
        decoration: BoxDecoration(
          color: color ?? ColorsHelper.gray1,
          borderRadius: BorderRadius.circular(radius ?? 16),
        ),
        child: Material(
          borderRadius: BorderRadius.circular(radius ?? 16),
          color: Colors.transparent,
          child: InkWell(
            splashColor: WidgetStateColor.resolveWith(
              (states) => Colors.white24,
            ),
            borderRadius: BorderRadius.circular(radius ?? 16),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AutoSizeText(
                  nameButton,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor ?? ColorsHelper.white,
                    fontSize: fontSize ?? 16,
                  ),
                ),
                (icon == null) ? SizedBox() : Gap(10),
                (icon == null) ? SizedBox.shrink() : icon,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Gradient gradient() =>
      LinearGradient(colors: [ColorsHelper.btn1, ColorsHelper.btn2]);

  static Widget buttonMain2(
    Function() onTap,
    String name, {
    double? width,
    double? height,
    double? fontSize,
        Color? color,
  }) {
    return Container(
      height: height ?? 4.5.h,
      width: width ?? 70.w,
      decoration: BoxDecoration(
        color: color??Color(0xff7DD3FC),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(1, 3),
          ),
        ],
        gradient: LinearGradient(
          colors: [ColorsHelper.btn1, ColorsHelper.btn2],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                color: ColorsHelper.textColor1,
                fontSize: fontSize ?? 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buttonMain3(
      Function() onTap,
      String name, {
        double? width,
        double? height,
        double? fontSize,
      }) {
    return Container(
      height: height ?? 4.5.h,
      width: width ?? 90.w,
      decoration: BoxDecoration(
        color: Color(0xffEBEAEC),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(1, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                color: Color(0xff3F414E),
                fontSize: fontSize ?? 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class ViewHelper {
  static void showLoading() {
    EasyLoading.show(
      indicator: Lottie.asset(Assets.animAnimLoading, width: 80),
      dismissOnTap: true,
    );
  }

  static String dateFormater(DateTime date) {
    final formater = intl.DateFormat("yyyy/MM/dd");
    return formater.format(date);
  }

  static String calculateDiscount(int price, int discount) {
    double amount = (price * discount) / 100;
    return (price - amount).toInt().toString();
  }

  static String calculateDiscountEn(int price, int discount) {
    double amount = (price * discount) / 100;
    return (price - amount).toInt().toString();
  }

  static void dismissLoading() {
    EasyLoading.dismiss();
  }

  // static Widget showEmptyList({double? width}) {
  //   return Lottie.asset(
  //     Assets.animsEmptyAnim,
  //     width: width ?? 250,
  //   );
  // }

  static String formatAmount(String price) {
    String priceInText = "";
    int counter = 0;
    for (int i = (price.length - 1); i >= 0; i--) {
      counter++;
      String str = price[i];
      if ((counter % 3) != 0 && i != 0) {
        priceInText = "$str$priceInText";
      } else if (i == 0) {
        priceInText = "$str$priceInText";
      } else {
        priceInText = ",$str$priceInText";
      }
    }
    return priceInText.trim();
  }

  static void showErrorDialog(BuildContext context, {String? text}) {
    Flushbar(
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      borderColor: Colors.red,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 150.0),
      animationDuration: const Duration(milliseconds: 500),
      messageText: AutoSizeText(
        text ?? "Please try again",
        maxLines: 1,
        minFontSize: 3,
        maxFontSize: 16.0,
        style: const TextStyle(color: Colors.red),
      ),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.error_outline, size: 28.0, color: Colors.red),
      duration: const Duration(seconds: 3),
    ).show(context);
  }

  static void showWarningDialog(BuildContext context, String text) {
    Flushbar(
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      borderColor: Colors.blue,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 150.0),
      animationDuration: const Duration(milliseconds: 500),
      messageText: AutoSizeText(
        text,
        maxLines: 1,
        minFontSize: 12,
        maxFontSize: 22.0,
        style: const TextStyle(color: Colors.blue),
      ),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.info_outline, size: 28.0, color: Colors.blue),
      duration: const Duration(seconds: 3),
      isDismissible: true,
    ).show(context);
  }

  static void showSuccessDialog(BuildContext context, String text) {
    Flushbar(
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      borderColor: Colors.green.shade700,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 100.0),
      animationDuration: const Duration(milliseconds: 500),
      messageText: AutoSizeText(
        text,
        maxLines: 1,
        minFontSize: 3,
        maxFontSize: 16.0,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.check_circle, size: 28.0, color: Colors.black),
      duration: const Duration(seconds: 3),
    ).show(context);
  }
}

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    ).hasMatch(this);
  }
}
