import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String imageUrl;
  final Function()? onTap;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.imageUrl,
    this.onTap,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();

    _init();
  }

  Future<void> _init() async {
    await _player.setUrl(widget.audioUrl, preload: true);

    _subscriptions.add(_player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));

    _subscriptions.add(_player.durationStream.listen((dur) {
      if (dur != null && mounted) {
        setState(() => _total = dur);
      }
    }));

    _subscriptions.add(_player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    }));
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _player.stop();
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadiusGeometry.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: widget.imageUrl.isNotEmpty
                ? Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  )
                : const SizedBox.shrink(),
          ),
          Slider(
            value: _position.inMilliseconds.toDouble(),
            max: _total.inMilliseconds.toDouble(),
            onChanged: (value) {
              _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_format(_position)), Text(_format(_total))],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay),
                onPressed: () => _player.seek(Duration.zero),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _isPlaying
                    ? () {
                        _player.pause();
                      }
                    : () {
                        _player.play();
                        if (widget.onTap != null) {
                          widget.onTap!();
                        }
                      },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _player.stop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
