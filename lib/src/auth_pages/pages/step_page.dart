import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/generated/assets.dart';
import 'package:zenrun/src/auth_pages/pages/login_page.dart';
import 'package:zenrun/src/auth_pages/pages/register_page.dart';

import '../../../core/widgets/Costance.dart';
import 'package:toln/toln.dart';

class StepPage extends StatefulWidget {
  const StepPage({super.key, required this.inviteEmail});
  final String inviteEmail;
  @override
  State<StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {


  @override
  void initState() {
    if (widget.inviteEmail != "") {
      context.to(RegisterPage(inviteEmail: widget.inviteEmail));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          color: Color(0xfffe4622),
          height: 100.h,
          width: 100.w,
          child: SingleChildScrollView(
            child: Column(
              children: [
                FittedBox(
                  child: Image.asset(
                    Assets.imagesSplashBg,
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 18.h,
                    width: 95.w,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // border: Border.all(color: Color(0xff969bff), width: 2),
                      // borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      spacing: 10,
                      children: [
                        UiHelper.buttonMain3(() {
                          context.to(LoginPage());
                        }, "Login",fontSize: 16,height: 4.5.h),
                        UiHelper.buttonMain3(() {
                          context.to(RegisterPage(inviteEmail: widget.inviteEmail,));
                        }, "Register",fontSize: 16,height: 4.5.h),
                      ],
                    ),
                  ),
                ),
                // SizedBox(height: 5.h,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
