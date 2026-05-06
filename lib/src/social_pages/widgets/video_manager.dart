import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';

class FlickMultiManager {
  final List<FlickManager> _flickManagers = [];
  FlickManager? _activeManager;
  bool _isMute = false;

  bool get isMuted => _isMute;

  void init(FlickManager flickManager) {
    _flickManagers.add(flickManager);
    if (_isMute) {
      flickManager.flickControlManager?.mute();
    } else {
      flickManager.flickControlManager?.unmute();
    }
    // اگر اولین ویدیو است، پخشش کن (اختیاری)
    if (_flickManagers.length == 1) {
      play(flickManager);
    }
  }

  void remove(FlickManager flickManager) {
    if (_activeManager == flickManager) {
      _activeManager = null;
    }
    flickManager.dispose();
    _flickManagers.remove(flickManager);
  }

  void dispose() {
    // کپی لیست برای جلوگیری از خطای ConcurrentModification
    final List<FlickManager> managers = List.from(_flickManagers);
    for (var item in managers) {
      item.dispose();
    }
    _flickManagers.clear();
  }

  void togglePlay(FlickManager flickManager) {
    if (_activeManager?.flickVideoManager?.isPlaying == true &&
        flickManager == _activeManager) {
      pause();
    } else {
      play(flickManager);
    }
  }

  void pause() {
    _activeManager?.flickControlManager?.pause();
  }

  void play([FlickManager? flickManager]) {
    if (flickManager != null) {
      // پاز کردن ویدیوی قبلی
      _activeManager?.flickControlManager?.pause();
      _activeManager = flickManager;
    }

    if (_isMute) {
      _activeManager?.flickControlManager?.mute();
    } else {
      _activeManager?.flickControlManager?.unmute();
    }

    _activeManager?.flickControlManager?.play();
  }

  void toggleMute() {
    _isMute = !_isMute;
    // اعمال وضعیت صدا روی تمام منیجرهای فعال در لیست
    for (var manager in _flickManagers) {
      if (_isMute) {
        manager.flickControlManager?.mute();
      } else {
        manager.flickControlManager?.unmute();
      }
    }
  }
}

class FeedPlayerPortraitControls extends StatelessWidget {
  const FeedPlayerPortraitControls({
    super.key,
    this.flickMultiManager,
    this.flickManager,
  });

  final FlickMultiManager? flickMultiManager;
  final FlickManager? flickManager;

  @override
  Widget build(BuildContext context) {
    FlickDisplayManager displayManager = FlickDisplayManager(
      flickManager: flickManager,
    );
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () {
          displayManager.handleShowPlayerControls();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            FlickAutoHideChild(
              showIfVideoNotInitialized: false,
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const FlickLeftDuration(),
                ),
              ),
            ),
            Expanded(
              child: FlickToggleSoundAction(
                toggleMute: () {
                  flickMultiManager?.toggleMute();
                  displayManager.handleShowPlayerControls();
                },
                child: const FlickSeekVideoAction(
                  child: Center(child: FlickVideoBuffer()),
                ),
              ),
            ),
            FlickAutoHideChild(
              autoHide: true,
              showIfVideoNotInitialized: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FlickSoundToggle(
                      toggleMute: () => flickMultiManager?.toggleMute(),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}