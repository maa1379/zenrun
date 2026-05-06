import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/generated/assets.dart';
import '../../api_models_repo/models/fasl_model.dart';
import '../../api_models_repo/models/task_model.dart';

class GlobalAudioPlayer {
  static final GlobalAudioPlayer _instance = GlobalAudioPlayer._internal();
  factory GlobalAudioPlayer() => _instance;

  final AudioPlayer player = AudioPlayer();
  String? currentPlayingUrl;

  Timer? _sleepTimer;
  RxInt sleepTimerRemaining = 0.obs; // زمان باقی‌مانده تایمر
  Timer? _countdownTimer;

  // متغیر برای مدیریت نوتیفیکیشن

  GlobalAudioPlayer._internal() {
    player.setLoopMode(LoopMode.all);
  }

  Future<void> setPlaylist(List<TaskModel> tasks, int startIndex) async {
    try {
      await player.stop();
      final audioSources = tasks.map((task) {
        return AudioSource.uri(
          Uri.parse(task.audioUrlEn ?? ""),
          tag: MediaItem(
            id: task.audioUrlEn ?? task.id.toString(),
            title: task.title ?? "ZenRun Track",
            album: "ZenRun Mixes",
            // عکس کاور در نوتیفیکیشن
            artUri: task.imageUrl != null ? Uri.parse(task.imageUrl!) : null,
          ),
        );
      }).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);

      // لود کردن کل لیست و شروع از آهنگی که کاربر کلیک کرده
      await player.setAudioSource(
          playlist,
          initialIndex: startIndex,
          initialPosition: Duration.zero
      );
      await player.play();
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  // 🌟 تنظیم تایمر توقف خودکار
  void setSleepTimer(int minutes) {
    cancelSleepTimer(); // لغو تایمر قبلی در صورت وجود

    if (minutes <= 0) return;

    sleepTimerRemaining.value = minutes;

    // شمارش معکوس برای نمایش به کاربر
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (sleepTimerRemaining.value > 0) {
        sleepTimerRemaining.value--;
      }
    });

    // تایمر اصلی برای توقف موزیک
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      player.pause(); // توقف موزیک پس از اتمام زمان
      cancelSleepTimer();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    sleepTimerRemaining.value = 0;
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({
    super.key,
    required this.taskList,
    required this.title,
    required this.faslModel,
  });

  final List<TaskModel> taskList;
  final String title;
  final FaslModel faslModel;

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final GlobalAudioPlayer _audioManager = GlobalAudioPlayer();

  Future<void> _playSong(int tappedIndex) async {
    final task = widget.taskList[tappedIndex];
    final url = task.audioUrlEn;

    // اگر آهنگ آدرسی برای پخش نداشت، کلا خارج شویم
    if (url == null || url.isEmpty) return;

    // گرفتن آیدی آهنگی که الان روی موتور جاست‌آدیو هست
    final currentMediaItem = _audioManager.player.sequenceState?.currentSource?.tag as MediaItem?;

    // آیدی این آهنگی که روش کلیک شده رو همونطور که موقع ساخت لیست تعریف کردیم می‌گیریم
    final targetId = task.audioUrlEn ?? task.id.toString();

    // ۱. اگر روی همون آهنگی که در حال پخشه کلیک کرده (حالت Pause/Play)
    if (currentMediaItem?.id == targetId) {
      if (_audioManager.player.playing) {
        await _audioManager.player.pause();
      } else {
        await _audioManager.player.play();
      }
      return;
    }

    // ۲. بررسی اینکه آیا لیستی که الان تو پلیر ست شده، دقیقاً همین لیست روی صفحه‌ست؟
    final currentPlaylist = _audioManager.player.sequenceState?.sequence;
    bool isSamePlaylist = false;

    if (currentPlaylist != null && currentPlaylist.length == widget.taskList.length) {
      // فقط به طول لیست اکتفا نمی‌کنیم! آیدی اولین آهنگ‌ها رو هم چک می‌کنیم که مطمئن شیم لیست همونه
      final firstItemIdInPlayer = (currentPlaylist.first.tag as MediaItem).id;
      final firstItemIdInWidget = widget.taskList.first.audioUrlEn ?? widget.taskList.first.id.toString();

      if (firstItemIdInPlayer == firstItemIdInWidget) {
        isSamePlaylist = true;
      }
    }

    // ۳. تغییر آهنگ
    if (isSamePlaylist) {
      // اگر لیست همون بود، فقط با یک پرش سریع (seek) میریم روی ایندکس جدید
      await _audioManager.player.seek(Duration.zero, index: tappedIndex);
      await _audioManager.player.play();
    } else {
      // اگر لیست فرق داشت (کاربر رفته بود تو یه آلبوم/فصل دیگه)، لیست جدید رو کلاً لود می‌کنیم
      await _audioManager.setPlaylist(widget.taskList, tappedIndex);
    }
  }

  TaskModel? get currentPlayingTask {
    try {
      // گرفتن تگ آهنگی که در موتور just_audio در حال پخش است
      final currentTag = _audioManager.player.sequenceState?.currentSource?.tag as MediaItem?;
      if (currentTag == null) return null;

      // پیدا کردن تسک مربوطه از داخل لیست
      return widget.taskList.firstWhere(
            (t) => t.audioUrlEn == currentTag.id || t.id.toString() == currentTag.id,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsHelper.white,
      appBar: AppBar(
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title.isNotEmpty ? widget.title : "Mixes",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      // 🌟 جادوی اصلی اینجاست: گوش دادن به تغییرات آهنگ
      body: StreamBuilder<SequenceState?>(
          stream: _audioManager.player.sequenceStateStream,
          builder: (context, snapshot) {

            // حالا در هر لحظه (حتی با زدن دکمه Next در نوتیفیکیشن) این مقدار درست آپدیت می‌شود
            final activeTask = currentPlayingTask;

            return widget.taskList.isEmpty
                ? const Center(child: Text("Empty", style: TextStyle(color: Colors.black)))
                : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: widget.taskList.length,
                    itemBuilder: (context, index) {
                      final task = widget.taskList[index];

                      // 🌟 چک کردن خیلی ساده‌تر شد!
                      final isPlaying = activeTask?.id == task.id;

                      return GestureDetector(
                        onTap: () => _playSong(index), // فراخوانی با ایندکس
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(task.imageUrl ?? ""),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) =>
                              const AssetImage(Assets.imagesLogo) as ImageProvider,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  ColorsHelper.btn2.withOpacity(0.4),
                                  Colors.white60,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 3)
                              ],
                              border: isPlaying
                                  ? Border.all(color: ColorsHelper.btn2, width: 2) // ضخامت بوردر را 2 کردم تا بهتر دیده شود
                                  : null,
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  task.title ?? "Unknown",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // نمایش مینی‌پلیر
                if (activeTask != null) _buildMiniPlayer(activeTask),
              ],
            );
          }
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _buildMiniPlayer(TaskModel currentTask) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: ColorsHelper.btn2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column( // Column اصلی اضافه شد تا نوار زمان زیر اطلاعات قرار بگیرد
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentTask.title ?? "Playing...",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "1 sound",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showTimerModal(context), // 👈 فراخوانی مودال تایمر
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() {
                      // نمایش زمان باقی‌مانده در صورت فعال بودن تایمر
                      int mins = _audioManager.sleepTimerRemaining.value;
                      return Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.black, size: 16),
                          const SizedBox(width: 4),
                          Text(
                              mins > 0 ? "$mins min" : "Timer",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<PlayerState>(
                  stream: _audioManager.player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing ?? false;

                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return Container(
                        margin: const EdgeInsets.all(10),
                        width: 24,
                        height: 24,
                        child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        if (playing) {
                          _audioManager.player.pause();
                        } else {
                          _audioManager.player.play();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 8), // فاصله بین هدر و نوار پیشرفت

            // --- بخش جدید: نوار پیشرفت و زمان ---
            StreamBuilder<Duration>(
              stream: _audioManager.player.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;

                return StreamBuilder<Duration?>(
                  stream: _audioManager.player.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;

                    // جلوگیری از خطای وقتی که هنوز زمان لود نشده
                    final double sliderMax = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
                    final double sliderValue = position.inSeconds.toDouble().clamp(0.0, sliderMax);

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                            activeTrackColor: Colors.black,
                            inactiveTrackColor: Colors.black26,
                            thumbColor: Colors.black,
                          ),
                          child: Slider(
                            min: 0.0,
                            max: sliderMax,
                            value: sliderValue,
                            onChanged: (value) {
                              // این بخش به کاربر اجازه میده آهنگ رو جلو و عقب ببره
                              _audioManager.player.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: Colors.black87, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: Colors.black87, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimerModal(BuildContext parentContext) {
    final times = [5, 10, 15, 30, 60, 120 , 180];

    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Stop playing after", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: times.map((time) {
                  return ActionChip(
                    label: Text("$time min"),
                    backgroundColor: ColorsHelper.btn2.withOpacity(0.3),
                    onPressed: () {
                      _audioManager.setSleepTimer(time);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text("Music will stop after $time minutes")),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  _audioManager.cancelSleepTimer();
                  Navigator.pop(context);
                },
                child: const Text("Cancel Timer", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
        );
      },
    );
  }

}