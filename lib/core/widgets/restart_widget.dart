import 'package:flutter/material.dart';

class RestartAppWidget extends StatefulWidget {
  const RestartAppWidget({super.key, required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartAppWidgetState>()?.restartApp();
  }

  @override
  _RestartAppWidgetState createState() => _RestartAppWidgetState();
}

class _RestartAppWidgetState extends State<RestartAppWidget> {
  bool restarting = false;

  void restartApp() async {
    restarting = true;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      setState(() {
        restarting = false;
      });
    });
    // setState(() {
    //   key = UniqueKey();
    // });
  }

  @override
  Widget build(BuildContext context) {
    if (restarting) {
      return const SizedBox();
    }
    return SizedBox(
      child: widget.child,
    );
  }
}
