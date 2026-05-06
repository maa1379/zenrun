import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenrun/src/api_models_repo/models/slider_model.dart';

import '../../../core/network/DataState.dart';
import '../../api_models_repo/api_service.dart';

class MainProvider extends ChangeNotifier {
  List<SliderModel> sliderList = [];
  bool loading = false;
  void update() => notifyListeners();
  PageController pageController = PageController(initialPage: 0);
  int activeIndex = 0;

  Future<void> getSliders() async {
    final res = await ApiService.instance.getSliders();
    if (res is DataSuccess) {
      sliderList.addAll(res.data ?? []);
      loading = true;
      notifyListeners();
    }
  }


  int stepCount = 0;
  int stepGoal = 20000;
  bool stepLoading = false;

  Future<void> loadStepsFromPrefs() async {
    stepLoading = false;
    final prefs = await SharedPreferences.getInstance();

    stepGoal = prefs.getInt('step_goal') ?? 20000;

    final raw = prefs.getString('daily_steps');
    if (raw != null) {
      final Map<String, dynamic> data = json.decode(raw);
      final steps = <String, int>{};
      data.forEach((key, value) {
        steps[key] = value;
      });

      final sortedKeys = steps.keys.toList()..sort();
      if (sortedKeys.isNotEmpty) {
        final latestKey = sortedKeys.last;
        stepCount = steps[latestKey] ?? 0;
      } else {
        stepCount = 0;
      }
    } else {
      stepCount = 0;
    }
    stepLoading = true;
    notifyListeners();
  }


}
