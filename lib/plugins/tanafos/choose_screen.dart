import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/plugins/tanafos/splash_2_screen.dart';

import '../../generated/assets.dart';
import 'core/dialog_view.dart';
import 'package:toln/toln.dart';

class BreathingMode {
  final String name;
  final List<Map<String, dynamic>> pattern;
  final String description;
  BreathingMode({
    required this.name,
    required this.pattern,
    required this.description,
  });
}

List<BreathCircle> breathCircles = [];

class BreathCircle {
  final double size;
  final double opacity;
  final Color color;

  BreathCircle({
    required this.size,
    required this.opacity,
    required this.color,
  });
}

final List<BreathingMode> modes = [
  BreathingMode(
    name: "Simple Breathing",
    description: """
    🔹The best choice for beginners.
    🔹Regulate breathing rhythm and reduce daily stress.
    🔹Perfect for starting the day or between busy tasks.
    """,
    pattern: [
      {
        "text": "Breathe in",
        "seconds": 4,
        "isRotate": false,
        "Hold2": false,
        "timeSec": false,
        "speak": "Inhale for 4 seconds",
      },
      {
        "text": "Breathe out",
        "seconds": 4,
        "isRotate": false,
        "Hold2": true,
        "timeSec": false,
        "speak": "Exhale for 4 seconds",
      },
    ],
  ),
  BreathingMode(
    name: "Respiration With Retention",
    description: """
    🔹Increased oxygen supply to the brain.
    🔹Calming the mind and body, especially in times of stress or anxiety.
    🔹Suitable for evenings or after work to relax.
    """,
    pattern: [
      {
        "text": "Breathe in",
        "seconds": 4,
        "isRotate": false,
        "Hold2": false,
        "timeSec": true,
        "speak": "Inhale for 4 seconds",
      },
      {
        "text": "Hold",
        "seconds": 4,
        "isRotate": true,
        "Hold2": false,
        "timeSec": true,
        "speak": "Hold your breath for 4 seconds",
      },
      {
        "text": "Breathe out",
        "seconds": 6,
        "isRotate": false,
        "Hold2": true,
        "timeSec": false,
        "speak": "Exhale for 6 seconds",
      },
    ],
  ),
  BreathingMode(
    name: "Breathing with hold after exhalation",
    description: """
    🔹Helps to stay relaxed after exhaling.
    🔹Increasing the body's tolerance to oxygen deprivation (stress tolerance).
    🔹Suitable before bedtime or deep meditations.
    """,
    pattern: [
      {
        "text": "Breathe in",
        "seconds": 4,
        "isRotate": false,
        "Hold2": false,
        "timeSec": false,
        "speak": "Inhale for 4 seconds",
      },
      {
        "text": "Breathe out",
        "seconds": 6,
        "isRotate": false,
        "Hold2": true,
        "timeSec": false,
        "speak": "Exhale for 6 seconds",
      },
      {
        "text": "Hold",
        "seconds": 4,
        "isRotate": true,
        "Hold2": true,
        "timeSec": false,
        "speak": "Hold your breath for 4 seconds",
      },
    ],
  ),
  BreathingMode(
    name: "Box Breathing",
    description: """
    🔹Strengthen mental focus.
    🔹Harmonizing the nervous system, reducing severe anxiety.
    🔹Used in the military and athletes for high concentration.
    """,
    pattern: [
      {
        "text": "Breathe in",
        "seconds": 4,
        "isRotate": false,
        "Hold2": false,
        "timeSec": false,
        "speak": "Inhale for 4 seconds",
      },
      {
        "text": "Hold",
        "seconds": 4,
        "isRotate": true,
        "Hold2": true,
        "timeSec": false,
        "speak": "Hold your breath for 4 seconds",
      },
      {
        "text": "Breathe out",
        "seconds": 4,
        "isRotate": false,
        "Hold2": true,
        "timeSec": false,
        "speak": "Exhale for 4 seconds",
      },
      {
        "text": "Hold",
        "seconds": 4,
        "isRotate": true,
        "Hold2": true,
        "timeSec": false,
        "speak": "Hold your breath for 4 seconds",
      },
    ],
  ),
];
const Color blueColor = Color(0xff64c9d1);

class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              context.rTo(Splash2Screen());
            },
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 26),
          ),
        ),
        backgroundColor: blueColor,
        body: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 70),
              Image.asset(Assets.imagesBreathing, height: 200),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    "In these sections, you must perform your breathing operations as described."
                        .toLn(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: ClampingScrollPhysics(),
                  itemCount: modes.length,
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    return Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        height: 45,
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
                              context.to(BreathingScreen(mode: mode));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: Text(
                                mode.name,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreathingScreen extends StatefulWidget {
  final BreathingMode mode;

  BreathingScreen({required this.mode});

  @override
  _BreathingScreenState createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController controller;
  bool isRotate = false;
  bool isHold2 = false;
  bool isTimeSec = false;
  int counter = 0;
  String phase = "";
  String speakText = "";
  Timer? timer;
  int phaseIndex = 0;
  double circleSize = 150;
  double glow = 20.0;

  final FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;

  Future<void> speak(String text) async {
    if (!isMuted) {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.4);
      await flutterTts.setVolume(1.0);
      await flutterTts.speak(text);
    }
  }

  void mute() {
    setState(() {
      isMuted = true;
    });
    flutterTts.stop();
  }

  void unMute() {
    setState(() {
      isMuted = false;
    });
  }

  void startBreathing() {
    counter = widget.mode.pattern[phaseIndex]["seconds"];
    phase = widget.mode.pattern[phaseIndex]["text"];
    isRotate = widget.mode.pattern[phaseIndex]["isRotate"];
    isHold2 = widget.mode.pattern[phaseIndex]["Hold2"];
    isTimeSec = widget.mode.pattern[phaseIndex]["timeSec"];
    speakText = widget.mode.pattern[phaseIndex]["speak"];
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: counter + 4),
    );
    speak(speakText);
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      setState(() {
        if (counter > 1) {
          if (isRotate) {
            controller.forward();
            setState(() {
              counter--;
            });
          } else {
            controller.reset();
            if (isHold2) {
              circleSize = 150;
            } else {
              circleSize = 350;
            }
            glow += 20;
            counter--;
          }
        } else {
          phaseIndex = (phaseIndex + 1) % widget.mode.pattern.length;
          isRotate = widget.mode.pattern[phaseIndex]["isRotate"];
          isTimeSec = widget.mode.pattern[phaseIndex]["timeSec"];
          isHold2 = widget.mode.pattern[phaseIndex]["Hold2"];
          counter = widget.mode.pattern[phaseIndex]["seconds"];
          phase = widget.mode.pattern[phaseIndex]["text"];
          speakText = widget.mode.pattern[phaseIndex]["speak"];
          speak(speakText);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    startBreathing();
  }

  @override
  void dispose() {
    flutterTts.stop();
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: blueColor,
          actions: [
            IconButton(
              onPressed: () {
                DialogView.showInfo(context, widget.mode.description, () {});
              },
              icon: Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
            isMuted
                ? IconButton(
                    onPressed: () {
                      unMute();
                    },
                    icon: Icon(Icons.volume_off, color: Colors.white, size: 30),
                  )
                : IconButton(
                    onPressed: () {
                      mute();
                    },
                    icon: Icon(Icons.volume_up, color: Colors.white, size: 30),
                  ),
            SizedBox(width: 20),
          ],
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
        ),
        bottomNavigationBar: Container(
          height: 50,
          width: 350,
          margin: EdgeInsets.only(bottom: 30, left: 30, right: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                DialogView.showDanger(context);
              },
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Text(
                  "Finish".toLn(),
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: blueColor,
        body: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                phase,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    counter.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              RotationTransition(
                turns: controller,
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * .5,
                  width: MediaQuery.sizeOf(context).width,
                  child: Center(
                    child: AnimatedContainer(
                      duration: Duration(seconds: counter),
                      height: circleSize,
                      width: circleSize,
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        padding: EdgeInsets.all(30),
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.10),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: glow,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: glow,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 80),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  height: 150,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white),
                                    color: Colors.white.withOpacity(0.10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: glow,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 80),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 150,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.10),
                                    border: Border.all(color: Colors.white),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: glow,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  height: 150,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.10),
                                    border: Border.all(color: Colors.white),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: glow,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  height: 150,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white),
                                    color: Colors.white.withOpacity(0.10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: glow,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class SubmitResultScreen extends StatelessWidget {
  SubmitResultScreen({super.key});

  final List<Map<String, String>> moods = [
    {"emoji": "😊", "label": "Positive"},
    {"emoji": "😌", "label": "Neutral"},
    {"emoji": "😟", "label": "Negative"},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: blueColor,
        body: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            children: [
              SizedBox(height: 150),
              Text(
                "How are you feeling right now?".toLn(),
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Expanded(
                child: GridView(
                  padding: EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  children: moods.map((mood) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white12,
                        border: Border.all(color: Colors.white),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          context.rTo(ChooseScreen());
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Text(
                              mood["emoji"]!,
                              style: TextStyle(fontSize: 35),
                            ),
                            Text(
                              mood["label"]!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
