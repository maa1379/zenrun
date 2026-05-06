import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';

import '../../generated/assets.dart';

class CustomScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? actions;
  final Widget? leading;
  final bool? withScaffold;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  const CustomScaffold({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.withScaffold,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: withScaffold == false?body:GestureDetector(
        onTap: (){
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          appBar: title != null ? UiHelper.appBar(title!,action: actions,leading: leading) : null,
          backgroundColor: Colors.white,
          body: Container(
            height: 100.h,
            width: 100.w,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesImg4),
                fit: BoxFit.cover,
              ),
            ),
            child: body,
          ),
          // extendBody: true,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }
}
