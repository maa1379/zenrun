import 'package:flutter/material.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/home_pages/pages/main_page.dart';

import '../../generated/assets.dart';
import 'choose_screen.dart';
import 'package:toln/toln.dart';

class Splash2Screen extends StatelessWidget {
  const Splash2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              context.rTo(MainPage());
            },
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 26),
          ),
        ),
        backgroundColor: blueColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 20,
          children: [
            Text(
              "Relax Breathing".toLn(),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Center(child: Image.asset(Assets.imagesRelax, width: 250)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Center(
                child: Text(
                  "this is a test which exercises your breathing and helps you calm down and temporarily remedy your panic attacks"
                      .toLn(),
                  textAlign: TextAlign.justify,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Center(
                child: Text(
                  "Note: If you have a specific problem or illness, consult your doctor before using the app's features to avoid any problems."
                      .toLn(),
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              height: 60,
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    context.to(ChooseScreen());
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      "Start".toLn(),
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
