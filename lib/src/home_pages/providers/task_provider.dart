import 'dart:typed_data';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/image_picker_helper.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/fasl_model.dart';
import 'package:zenrun/src/api_models_repo/models/profile_model.dart';
import 'package:zenrun/src/api_models_repo/models/task_model.dart';

import '../../api_models_repo/ai_service.dart';
import '../../api_models_repo/models/user_task_model.dart';

enum ViewState { Idle, Loading, Success, Error }

class TaskProvider extends ChangeNotifier {
  ViewState _state = ViewState.Idle;
  ViewState get state => _state;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void sortTaskList(List<TaskModel> list) {
    list.sort((a, b) {
      if (a.date == null || b.date == null) return 0;
      return a.date!.compareTo(b.date!);
    });
    notifyListeners();
  }

  List<FaslModel> faslList = [];
  List<UserTaskModel> userTaskList = [];
  Set<String> _completedTaskIds = {};

  List<ProfileModel> userList = [];
  List<AiImageModel> imageProcessed = [];
  bool isTaskActionDone = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  ChewieController? get chewieController => _chewieController;
  bool _hasWatchedToEnd = false;
  List<TaskModel> allTasks = [];

  String? smileUrl;
  String? videoUrl;
  SelectedMedia? smileUint8;
  SelectedMedia? videoUint8;

  // منطق دقیق‌تر برای انقضای تسک
  bool isTaskExpired(TaskModel task) {
    if (task.isDaily != true) return false;
    if (task.date == null) return false;

    final now = DateTime.now();
    // اگر تاریخ تسک برای روزهای قبل باشد، منقضی شده است
    final taskDate = task.date!;
    final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);
    final today = DateTime(now.year, now.month, now.day);

    return taskDay.isBefore(today);
  }

  bool isTaskCompleted(String taskId) => _completedTaskIds.contains(taskId);

  Future<void> fetchAllData() async {
    allTasks.clear();
    _setState(ViewState.Loading);
    try {
      final results = await Future.wait([
        ApiService.instance.getFaslList(),
        ApiService.instance.getTaskList(),
        ApiService.instance.getUserTaskList(),
      ]);

      final faslResponse = results[0] as DataState<List<FaslModel>>;
      if (faslResponse is DataSuccess) {
        faslList = faslResponse.data ?? [];
      } else {
        throw Exception("Failed to load seasons");
      }

      final taskResponse = results[1] as DataState<List<TaskModel>>;
      if (taskResponse is DataSuccess) {
        allTasks = taskResponse.data ?? [];
      } else {
        throw Exception("Failed to load tasks");
      }

      await _processUserTasks(results[2] as DataState<List<UserTaskModel>>);

      final faslMap = {for (var fasl in faslList) fasl.id: fasl};
      for (var task in allTasks) {
        if (faslMap.containsKey(task.faslid)) {
          faslMap[task.faslid]!.taskList ??= [];
          faslMap[task.faslid]!.taskList!.add(task);
        }
      }

      _setState(ViewState.Success);
    } catch (e) {
      debugPrint("Error fetching data: $e");
      _setState(ViewState.Error);
    }
  }

  Future<void> refreshUserTasks() async {
    final res = await ApiService.instance.getUserTaskList();
    await _processUserTasks(res);
    notifyListeners();
  }

  Future<void> _processUserTasks(DataState<List<UserTaskModel>> res) async {
    if (res is DataSuccess) {
      userTaskList = res.data ?? [];
      _completedTaskIds.clear();
      final taskMap = {for (var task in allTasks) task.id: task};

      for (final userTask in userTaskList) {
        if (userTask.taskId == null) continue;
        final task = taskMap[userTask.taskId!];

        if (task == null) {
          _completedTaskIds.add(userTask.taskId!.toString());
          continue;
        }

        if (task.isInvite == true) {
          final requiredInvites = task.inviteCount ?? 0;
          final actualInvites = userTask.inviteCount ?? 0;
          if (actualInvites >= requiredInvites && requiredInvites > 0) {
            _completedTaskIds.add(userTask.taskId!.toString());
          }
        } else {
          _completedTaskIds.add(userTask.taskId!.toString());
        }
      }
    } else {
      throw Exception("Failed to load user tasks");
    }
  }

  Future<void> initializeVideoPlayer(String? videoUrl) async {
    if (videoUrl == null || videoUrl.isEmpty) return;
    await disposeVideoPlayer();

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );
      _videoPlayerController!.addListener(_checkIfVideoWatchedToEnd);
      _hasWatchedToEnd = false;
      isTaskActionDone = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  void _checkIfVideoWatchedToEnd() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) return;
    final position = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;

    if (!_hasWatchedToEnd && duration > Duration.zero && (duration - position).inSeconds <= 1) {
      _hasWatchedToEnd = true;
      setMediaAsDone(true); // آپدیت وضعیت
    }
  }

  Future<void> disposeVideoPlayer() async {
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_checkIfVideoWatchedToEnd);
      await _videoPlayerController!.pause();
      await _videoPlayerController!.dispose();
    }
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
  }

  void clearMediaSelection() {
    smileUrl = null;
    videoUrl = null;
    smileUint8 = null;
    videoUint8 = null;
    isTaskActionDone = false;
    imageProcessed.clear();
    // به جای notifyListeners اینجا، در UI صدا زده می‌شود تا ریکربیلد اضافه رخ ندهد
  }

  void setMediaAsDone(bool isDone) {
    if (isTaskActionDone != isDone) {
      isTaskActionDone = isDone;
      notifyListeners();
    }
  }

  Future<bool> setUserTask(
      String taskId,
      String? fileURL,
      String isLevelUpDone,
      String userCount,
      BuildContext context,
      ) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.setUserTask(
      id: "0",
      taskId: taskId,
      fileURL: fileURL?.isEmpty ?? true ? null : fileURL,
      isLevelUpDone: isLevelUpDone,
      userCount: userCount,
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      await refreshUserTasks();
      return true;
    } else {
      ViewHelper.showErrorDialog(context);
      return false;
    }
  }

  Future<bool> setTaskCoin(String coin, String RCoin, String ZCoin, String SCoin) async {
    final res = await ApiService.instance.setAddCoin(
      coin: coin,
      RCoin: RCoin,
      ZCoin: ZCoin,
      SCoin: SCoin,
    );
    return res is DataSuccess;
  }

  bool canDoTaskInFasl({
    required FaslModel fasl,
    required TaskModel currentTask,
  }) {
    final tasks = fasl.taskList ?? [];
    final index = tasks.indexWhere((t) => t.id == currentTask.id);

    if (index <= 0) return true; // اولین تسک همیشه باز است

    // اگر تسک قبلی منقضی شده باشد، باید اجازه بدهیم تسک بعدی انجام شود
    final previousTask = tasks[index - 1];
    if (isTaskExpired(previousTask)) return true;

    return isTaskCompleted(previousTask.id.toString());
  }

  Future<void> getProfile() async {
    final res = await ApiService.instance.getAllProfile();
    if (res is DataSuccess) {
      final email = await PrefHelpers.getUser();
      userList = res.data?.where((user) =>
      user.email != email && user.isDeleted != true && user.isActive != false)
          .toList() ?? [];
      notifyListeners();
    }
  }



  double get dailyProgressPercentage {
    if (allTasks.isEmpty) return 0.0;

    // Filter out expired tasks from the total count logic if needed,
    // but usually progress is based on "available" tasks.
    // For now, keeping logic based on *completed* today.
    final completedTodayIds = userTaskList
        .where((userTask) => userTask.date?.isSameDay(DateTime.now()) ?? false)
        .map((e) => e.taskId)
        .toSet();

    if (completedTodayIds.isEmpty) return 0.0;

    // Count valid tasks completed
    final completedCount = allTasks.where((task) => completedTodayIds.contains(task.id)).length;

    return (completedCount / allTasks.length) * 100;
  }

  Map<DateTime, int> get last7DaysCompletedTasks {
    final Map<DateTime, int> dailyCounts = {};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayOnly = DateTime(date.year, date.month, date.day);
      dailyCounts[dayOnly] = 0;
    }

    for (final userTask in userTaskList) {
      if (userTask.date != null) {
        final taskDayOnly = DateTime(userTask.date!.year, userTask.date!.month, userTask.date!.day);
        if (dailyCounts.containsKey(taskDayOnly)) {
          dailyCounts[taskDayOnly] = dailyCounts[taskDayOnly]! + 1;
        }
      }
    }
    return dailyCounts;
  }

}

extension DateTimeCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
