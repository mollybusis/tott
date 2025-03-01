import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:talk_of_the_town/Components/audio_recorder.dart';

class AudioPlayerComponent extends StatefulWidget {
  AudioPlayer audioPlayer;
  Duration position;
  File? audioFile;
  AudioPlayerComponent(this.audioPlayer, this.position, this.audioFile, {super.key});

  @override
  State<AudioPlayerComponent> createState() => _AudioPlayerComponentState();
}

class _AudioPlayerComponentState extends State<AudioPlayerComponent> {
  bool isPlayable = false;
  bool isPlaying = false;
  bool isComplete = false;

  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    widget.audioPlayer.onDurationChanged.listen((newDuration) {
      if(mounted){
        setState(() => duration = newDuration);
      }
    });

    widget.audioPlayer.onPositionChanged.listen((newPosition) {
      if(mounted) {
        setState(() => widget.position = newPosition);
        setState(() {
          isComplete = widget.audioPlayer.state == PlayerState.completed;
        });
      }
    });
    
    widget.audioPlayer.onSeekComplete.listen((event){
      print("SEEKING COMPLETE>>>>>>>>>!!!!!");
      //await widget.audioPlayer.pause();
    });

    widget.audioPlayer.onPlayerComplete.listen((event) async {
      print("AUDIO IS DONE PLAYING");
      setState(() {
        isComplete = widget.audioPlayer.state == PlayerState.completed;
      });

      if(mounted) {
        print("Audio completed. About to try and reset the source...???");

        setState(() {
          widget.audioPlayer.setSourceDeviceFile(widget.audioFile!.path);
        });

        // setState(() {
        //   widget.audioPlayer.setSourceDeviceFile((widget.audioPlayer.source)!.path);
        // });


        // Set position to zero
        setState(() => widget.position = Duration.zero);
        print("setState widget position to 0");

        // Seek to the beginning and log
        print("Player state before seek: ${widget.audioPlayer.state}");
        if (widget.audioPlayer.state != PlayerState.playing) {
          print("Player is not in playing state, seeking might fail");}

        await widget.audioPlayer.seek(Duration.zero).timeout(const Duration(seconds: 10));
        print("Seeked to the beginning.");



        // Resume playback
        await widget.audioPlayer.pause();
        print("Paused.");
        //setState(() => widget.position = Duration.zero);
      }

    });

    print("Init state happened");
  }

  @override
  void dispose() {
    widget.audioPlayer.dispose();

    super.dispose();
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final twoDigitMinutes =
    twoDigits(d.inMinutes.remainder(60));
    final twoDigitSeconds =
    twoDigits(d.inSeconds.remainder(60));

    return "$twoDigitMinutes:$twoDigitSeconds";
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // TODO: figure out how to make it playable once it
          Slider(
            min: 0,
            max: duration.inMilliseconds.toDouble(),
            value: widget.position.inMilliseconds.toDouble(),
            onChanged: (value) async {
              final pos = Duration(milliseconds: value.toInt());
              if(widget.audioPlayer.state == PlayerState.completed){
                print("it's completed");
                setState(() => widget.position = const Duration(milliseconds: 0));
                await widget.audioPlayer.resume();
              }
              if (widget.audioPlayer.state == PlayerState.playing || widget.audioPlayer.state == PlayerState.paused) {
                print("gonna seek");
                await widget.audioPlayer.seek(pos).timeout(const Duration(seconds: 10));
                print("We seeked");
                setState(() => widget.position = pos);
                if(widget.audioPlayer.state == PlayerState.playing){
                  await widget.audioPlayer.resume();
                }
                else{
                  await widget.audioPlayer.pause(); //just changed this from resume
                }
                //await widget.audioPlayer.pause(); //just changed this from resume
              }

              // await widget.audioPlayer.seek(pos);
              // setState(() => widget.position = pos);
              // await widget.audioPlayer.resume();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatTime(widget.position)),
                Text(formatTime(duration - widget.position))
              ],
            ),
          ),
          CircleAvatar(
            radius: 35,
            child: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 50,
              onPressed: () async {
                if (isPlaying) {
                  await widget.audioPlayer.pause();
                } else {
                  //check the position
                  //if it's at the end, put it to zero
                  if(isComplete){
                    print("OH YEAH ITS COMPLETE HELL YEAH");
                    await widget.audioPlayer.seek(Duration.zero);
                  }

                  await widget.audioPlayer.resume();
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
