import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioBubble extends StatefulWidget {
  const AudioBubble(
      {super.key,
      required this.filepath,
      required this.isNetwork,
      required this.isMe,
      required this.seenTime,
      required this.player});

  final String filepath;
  final bool isNetwork;
  final bool isMe;
  final Widget seenTime;
  final AudioPlayer player;

  @override
  State<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<AudioBubble> {
  Duration? duration;
  bool isBuild = false;

  @override
  Widget build(BuildContext context) {
    if (!isBuild) {
      if (widget.isNetwork) {
        widget.player
            .setUrl(widget.filepath.startsWith("https") ||
                    widget.filepath.startsWith("http")
                ? widget.filepath
                : widget.filepath)
            .then((value) {
          duration = value;
        });
      } else {
        widget.player.setFilePath(widget.filepath).then((value) {
          duration = value;
        });
      }
      isBuild = true;
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .1,
        width: MediaQuery.of(context).size.width * .6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 12, right: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: (widget.isMe) ? Colors.red : Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StreamBuilder<PlayerState>(
                          stream: widget.player.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState =
                                playerState?.processingState;
                            final playing = playerState?.playing;
                            if (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering) {
                              return GestureDetector(
                                onTap: widget.player.play,
                                child: Icon(Icons.play_arrow,color: widget.isMe?Colors.white:Colors.black,),
                              );
                            } else if (playing != true) {
                              return GestureDetector(
                                onTap: widget.player.play,
                                child: Icon(Icons.play_arrow,color: widget.isMe?Colors.white:Colors.black,),
                              );
                            } else if (processingState !=
                                ProcessingState.completed) {
                              return GestureDetector(
                                onTap: widget.player.pause,
                                child: Icon(Icons.pause,color: widget.isMe?Colors.white:Colors.black,),
                              );
                            } else {
                              return GestureDetector(
                                child: Icon(Icons.replay,color: widget.isMe?Colors.white:Colors.black,),
                                onTap: () {
                                  widget.player.seek(Duration.zero);
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StreamBuilder<Duration>(
                            stream: widget.player.positionStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: snapshot.data!.inMilliseconds /
                                          (duration?.inMilliseconds ?? 1),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          prettyDuration(
                                              snapshot.data! == Duration.zero
                                                  ? duration ?? Duration.zero
                                                  : snapshot.data!),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: (widget.isMe)
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return const LinearProgressIndicator();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    widget.seenTime,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String prettyDuration(Duration d) {
    var min = d.inMinutes < 10 ? "0${d.inMinutes}" : d.inMinutes.toString();
    var sec = d.inSeconds < 10 ? "0${d.inSeconds}" : d.inSeconds.toString();
    return "$min:$sec";
  }
}
