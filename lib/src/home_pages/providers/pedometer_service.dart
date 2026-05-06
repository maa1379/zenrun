import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';

import '../../api_models_repo/models/setting_model.dart';

/// ================== KEYS ==================
const String kLastSensorValue = 'last_sensor_value';
const String kTotalStepCounter = 'total_step_counter';
const String kDayTotalOffset = 'day_total_offset';
const String kOffsetDate = 'offset_date';
const String kMilestoneDate = 'milestone_date';
const String kHistoricalSteps = 'historical_steps';
const String kHistoricalDistance = 'historical_distance';
const String kHistoricalCalories = 'historical_calories';
const String kCollectedMilestones = 'collected_milestones';

const String _notificationChannelId = 'pedometer_service';
const int kBatchSaveSeconds = 30;

/// ================== Helpers ==================
String _todayKey([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

Map<String, dynamic> _decodeMap(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    return json.decode(raw) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

String _encodeMap(Map m) => json.encode(m);

List<String> _lastNDaysKeys(int n) {
  final now = DateTime.now();
  return List.generate(n, (i) {
    final d = now.subtract(Duration(days: n - 1 - i));
    return _todayKey(d);
  });
}

@pragma('vm:entry-point')
void stepService(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // load persisted service state (اگر وجود داشته باشد)
  int? lastSensorValue = prefs.getInt(
    kLastSensorValue,
  ); // null => offset belum set
  int totalStepCounter = prefs.getInt(kTotalStepCounter) ?? 0;
  String offsetDate = prefs.getString(kOffsetDate) ?? '';
  int dayTotalOffset = prefs.getInt(kDayTotalOffset) ?? 0;

  Map<String, int> dailySteps = _decodeMap(
    prefs.getString(kHistoricalSteps),
  ).map((k, v) => MapEntry(k, (v as num).toInt()));

  StreamSubscription<StepCount>? subscription;

  // اگر سرویس از قبل channel notification لازم دارد بسازیم (Android)
  if (Platform.isAndroid) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      'ZenRun Pedometer',
      description: 'Step counter service is running.',
      importance: Importance.low,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> persistServiceState() async {
    try {
      await prefs.setInt(kLastSensorValue, lastSensorValue ?? 0);
      await prefs.setInt(kTotalStepCounter, totalStepCounter);
      await prefs.setString(kOffsetDate, offsetDate);
      await prefs.setInt(kDayTotalOffset, dayTotalOffset);
      await prefs.setString(kHistoricalSteps, _encodeMap(dailySteps));
    } catch (e) {
      if (kDebugMode) print("persist error: $e");
    }
  }

  void updateNotification(int steps) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'ZenRun',
        content: 'Steps today: $steps',
      );
    }
  }

  Future<void> initOffsetIfNeeded(int sensorValue) async {
    // اگر lastSensorValue null باشد یعنی اولین اجرای واقعی هست و باید offset اولیه ست شود
    if (lastSensorValue == null) {
      lastSensorValue = sensorValue;
      offsetDate = _todayKey();
      dayTotalOffset = totalStepCounter; // معمولاً صفر است، ولی امن است
      await persistServiceState();
      if (kDebugMode) print("Service: initial offset set -> $sensorValue");
    }
  }

  Future<void> processSensor(int sensorValue) async {
    await initOffsetIfNeeded(sensorValue);

    // محاسبه delta
    int delta;
    if (sensorValue >= (lastSensorValue ?? 0)) {
      delta = sensorValue - (lastSensorValue ?? 0);
    } else {
      // سنسور ریست شده (مثلاً ریبوت) => شمارنده سنسور از صفر شروع شده
      delta = sensorValue;
    }

    totalStepCounter += delta;
    lastSensorValue = sensorValue;

    final today = _todayKey();
    if (today != offsetDate) {
      // روز جدید؛ offset روز جدید = totalStepCounter الان
      offsetDate = today;
      dayTotalOffset = totalStepCounter;
    }

    int todaySteps = totalStepCounter - dayTotalOffset;
    if (todaySteps < 0) todaySteps = 0;

    dailySteps[today] = todaySteps;

    // نوتیف و اطلاع UI
    updateNotification(todaySteps);

    try {
      service.invoke('stepsUpdated', {'steps': todaySteps});
    } catch (e) {
      if (kDebugMode) print("invoke error: $e");
    }

    // persist state (setInt سریع است)
    await persistServiceState();
  }

  // Reconnect-safe stream starter
  void startStream() {
    subscription?.cancel();
    subscription = Pedometer.stepCountStream.listen(
      (event) async {
        try {
          await processSensor(event.steps);
        } catch (e) {
        }
      },
      onError: (e) {
        Future.delayed(const Duration(seconds: 2), startStream);
      },
      cancelOnError: true,
    );
  }

  // شروع استریم
  startStream();

  // event handlers: وقتی اپ درخواست persist یا stop کرد
  service.on('persistNow').listen((event) async {
    await persistServiceState();
  });

  service.on('stopService').listen((event) async {
    try {
      await subscription?.cancel();
      await persistServiceState();
    } finally {
      service.stopSelf();
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// ================== HealthData Provider (یکپارچه و پایدار) ==================
class HealthData extends ChangeNotifier {
  StreamSubscription<Map<String, dynamic>?>? _bgSubscription;
  Timer? _periodicSaveTimer;

  final StreamController<int> _stepStreamController =
      StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepStreamController.stream;

  bool _isLoading = true;
  String? _errorMessage;

  int _currentDaySteps = 0;
  String _today = '';
  Map<String, int> _dailySteps = {}; // keyed by yyyy-MM-dd
  Map<String, double> _distanceHistory = {};
  Map<String, double> _caloriesHistory = {};
  Set<String> _collectedMilestones = {};

  // service internal state mirror (optional)
  int? _lastSensorValue;
  int _totalStepCounter = 0;
  int _dayTotalOffset = 0;
  String _offsetDate = '';

  static const double _avgStepLengthMeters = 0.762;
  static const double _caloriesPerStep = 0.04;

  SettingModel? _settings; // از API می‌آید (در صورت نیاز)

  HealthData() {
    _today = _todayKey();
    _initialize();
  }

  // ---------- public getters ----------
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentDaySteps => _currentDaySteps;
  Map<String, int> get dailySteps => Map.unmodifiable(_dailySteps);
  Map<String, double> get distanceHistory => Map.unmodifiable(_distanceHistory);
  Map<String, double> get caloriesHistory => Map.unmodifiable(_caloriesHistory);
  Set<String> get collectedMilestones => Set.unmodifiable(_collectedMilestones);

  List<RewardMilestone> get rewardMilestones {
    if (_settings == null) return [];
    final ms = <RewardMilestone?>[
      _parseMilestone("RCoin1", _settings!.rCoin1),
      _parseMilestone("RCoin2", _settings!.rCoin2),
      _parseMilestone("RCoin3", _settings!.rCoin3),
      _parseMilestone("RCoin4", _settings!.rCoin4),
      _parseMilestone("RCoin5", _settings!.rCoin5),
      _parseMilestone("RCoin6", _settings!.rCoin6),
      _parseMilestone("RCoin7", _settings!.rCoin7),
      _parseMilestone("RCoin8", _settings!.rCoin8),
      _parseMilestone("RCoin9", _settings!.rCoin9),
      _parseMilestone("RCoin10", _settings!.rCoin10),
    ];
    final valid = ms.whereType<RewardMilestone>().toList();
    valid.sort((a, b) => a.steps.compareTo(b.steps));
    return valid;
  }

  RewardMilestone? _parseMilestone(String key, String? rCoinString) {
    if (rCoinString == null || rCoinString.isEmpty) return null;
    try {
      final parts = rCoinString.split('-');
      if (parts.length == 2) {
        final steps = int.parse(parts[0]);
        final reward = int.parse(parts[1]);
        if (steps > 0) {
          return RewardMilestone(key: key, steps: steps, reward: reward);
        }
      }
    } catch (e) {
      if (kDebugMode) print("parseMilestone error: $e");
    }
    return null;
  }

  // ---------- initialization ----------
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    _settings = (await ApiService.instance.getSetting()).data;
    // 1. permissions
    await _requestPermissions();

    // 2. load local data
    await _loadAllFromPrefs();

    // 3. init background service (but don't auto start it here; start after permission)
    await _configureBackgroundService();

    // 4. if permission granted, start service and listener
    final perm = await Permission.activityRecognition.status;
    if (perm.isGranted) {
      await _startBackgroundListener();
      // start service only if not running
      final svc = FlutterBackgroundService();
      if (!await svc.isRunning()) {
        svc.startService();
      }
    }

    // 5. periodic save for UI-managed metrics
    _periodicSaveTimer = Timer.periodic(
      Duration(seconds: kBatchSaveSeconds),
      (_) => _saveAllData(),
    );

    _isLoading = false;
    notifyListeners();
  }

  // ---------- permissions ----------
  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final res = await Permission.activityRecognition.request();
        if (!res.isGranted) {
          if (kDebugMode) print("Activity recognition permission not granted");
        }
        await Permission.notification.request();
      } else if (Platform.isIOS) {
        await Permission.sensors.request();
      }
    } catch (e) {
      if (kDebugMode) print("permission error: $e");
    }
  }

  // ---------- prefs load/save ----------
  Future<void> _loadAllFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load service-mirroring keys safely but only if permission already granted.
    // اینکار باعث جلوگیری از پذیرش مقادیر قدیمی قبل از کالیبراسیون می‌شود.
    final perm = await Permission.activityRecognition.status;
    if (perm.isGranted) {
      _lastSensorValue = prefs.getInt(kLastSensorValue);
      _totalStepCounter = prefs.getInt(kTotalStepCounter) ?? 0;
      _dayTotalOffset = prefs.getInt(kDayTotalOffset) ?? 0;
      _offsetDate = prefs.getString(kOffsetDate) ?? '';
    } else {
      // اگر پرمیشن نیست، نباید state سرویس را trust کنیم؛ آنها را null/0 بگذار
      _lastSensorValue = null;
      _totalStepCounter = 0;
      _dayTotalOffset = 0;
      _offsetDate = '';
    }

    // Load histories (safe)
    _dailySteps = _decodeMap(
      prefs.getString(kHistoricalSteps),
    ).map((k, v) => MapEntry(k, (v as num).toInt()));
    _distanceHistory = _decodeMap(
      prefs.getString(kHistoricalDistance),
    ).map((k, v) => MapEntry(k, (v as num).toDouble()));
    _caloriesHistory = _decodeMap(
      prefs.getString(kHistoricalCalories),
    ).map((k, v) => MapEntry(k, (v as num).toDouble()));
    _collectedMilestones = (prefs.getStringList(kCollectedMilestones) ?? [])
        .toSet();


    String currentTodayKey = _todayKey();
    String lastMilestoneDate = prefs.getString(kMilestoneDate) ?? '';

    if (lastMilestoneDate != currentTodayKey) {
      // اگر تاریخ عوض شده، جوایز قبلی پاک شوند
      _collectedMilestones = {};
      // تاریخ جدید را ست کن تا امروز دیگر ریست نشود
      await prefs.setString(kMilestoneDate, currentTodayKey);
      await prefs.remove(kCollectedMilestones);
    } else {
      // اگر همان روز است، لیست قبلی را لود کن
      _collectedMilestones =
          (prefs.getStringList(kCollectedMilestones) ?? []).toSet();
    }


    // Ensure today's key exists (prevent UI clearing on refresh)
    final todayKey = _todayKey();
    if (!_dailySteps.containsKey(todayKey)) _dailySteps[todayKey] = 0;
    if (!_distanceHistory.containsKey(todayKey)) {
      _distanceHistory[todayKey] = 0.0;
    }
    if (!_caloriesHistory.containsKey(todayKey)) {
      _caloriesHistory[todayKey] = 0.0;
    }

    // Also ensure last 7 days keys exist (so chart always shows 7 bars)
    for (final k in _lastNDaysKeys(7)) {
      if (!_dailySteps.containsKey(k)) _dailySteps[k] = 0;
      if (!_distanceHistory.containsKey(k)) _distanceHistory[k] = 0.0;
      if (!_caloriesHistory.containsKey(k)) _caloriesHistory[k] = 0.0;
    }

    _stepStreamController.add(_currentDaySteps);
    // set currentDaySteps from map (trusted)
    _currentDaySteps = _dailySteps[_todayKey()] ?? 0;
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(kHistoricalSteps, _encodeMap(_dailySteps));
      await prefs.setString(kHistoricalDistance, _encodeMap(_distanceHistory));
      await prefs.setString(kHistoricalCalories, _encodeMap(_caloriesHistory));
      await prefs.setStringList(
        kCollectedMilestones,
        _collectedMilestones.toList(),
      );
      await prefs.setString(kMilestoneDate, _todayKey());
    } catch (e) {
      if (kDebugMode) print("saveAllData error: $e");
    }
  }

  // ---------- background service config & listener ----------
  Future<void> _configureBackgroundService() async {
    final service = FlutterBackgroundService();

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _notificationChannelId,
        'ZenRun Pedometer',
        description: 'Step counter service is running.',
        importance: Importance.low,
      );

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: stepService,
        autoStart: false,
        isForegroundMode: true,
        autoStartOnBoot: true,
        foregroundServiceNotificationId: 888,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'ZenRun Pedometer',
        initialNotificationContent: 'Counting steps...',
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: stepService,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> _startBackgroundListener() async {
    final service = FlutterBackgroundService();
    final perm = await Permission.activityRecognition.status;
    if (!perm.isGranted) {
      if (kDebugMode) print("Permission not granted -> not starting service");
      return;
    }

    // ensure service running
    if (!await service.isRunning()) {
      await service.startService();
    }

    // cancel old subscription
    await _bgSubscription?.cancel();

    // subscribe to events from service
    _bgSubscription = service.on('stepsUpdated').listen((event) {
      if (event != null && event.containsKey('steps')) {
        final steps = (event['steps'] as num).toInt();
        _onServiceSteps(steps);
      }
    });
  }

  Future<void> refreshData() async {
    // این تابع باید امن باشه و داده‌ها را پاک نکند.
    await _requestPermissions(); // دوباره چک می‌کنیم
    await _loadAllFromPrefs();
    await _startBackgroundListener();
    // recalculations
    _metricsRecalc();
    notifyListeners();
  }

  void _onServiceSteps(int calculatedSteps) {
    final newTodayKey = _todayKey();
    if (_today != newTodayKey) {
      _today = newTodayKey; // آپدیت کردن تاریخ امروز
      _collectedMilestones.clear(); // ریست کردن جوایز گرفته شده
      _saveAllData(); // ذخیره وضعیت خالی برای روز جدید
    }
    _currentDaySteps = calculatedSteps;

    _distanceHistory[_today] = _currentDaySteps * _avgStepLengthMeters;
    _caloriesHistory[_today] = _currentDaySteps * _caloriesPerStep;
    _dailySteps[_today] = _currentDaySteps;

    _stepStreamController.add(_currentDaySteps);
    _metricsRecalc();
    notifyListeners();
  }

  void _metricsRecalc() {
    _metrics = HealthMetrics(
      distance:
          _distanceHistory[_today] ?? (_currentDaySteps * _avgStepLengthMeters),
      calories:
          _caloriesHistory[_today] ?? (_currentDaySteps * _caloriesPerStep),
    );
  }

  // ---------- UI actions ----------
  HealthMetrics _metrics = HealthMetrics(distance: 0, calories: 0);
  HealthMetrics get metrics => _metrics;

  void collectReward(String key) async {
    if (_collectedMilestones.contains(key)) return;
    _collectedMilestones.add(key);
    _saveAllData();
    notifyListeners();
  }

  bool isMilestoneCollected(String key) => _collectedMilestones.contains(key);

  void disposed() {
    stop();
    _stepStreamController.close();
  }

  Future<void> stop() async {
    await _bgSubscription?.cancel();
    _periodicSaveTimer?.cancel();
    await _saveAllData();
    // signal service to persist and stop if desired
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('persistNow');
    }
  }
}

/// ================== Simple Models ==================
class RewardMilestone {
  final String key;
  final int steps;
  final int reward;
  RewardMilestone({
    required this.key,
    required this.steps,
    required this.reward,
  });
}

class HealthMetrics {
  final double distance;
  final double calories;
  HealthMetrics({required this.distance, required this.calories});
}
