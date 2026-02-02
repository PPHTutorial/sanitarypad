import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String url;
  final String movieId;

  const CustomVideoPlayer(
      {super.key, required this.url, required this.movieId});

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  Duration? savedPosition;
  Duration? seekToPosition;

  Future<Duration> _loadSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt("movie_${widget.movieId}_position") ?? 0;

    if (ms > 0) {
      savedPosition = Duration(milliseconds: ms);
    }
    return Duration(milliseconds: ms);
  }

  Future<void> _savePosition(VideoPlayerController videoController) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      "movie_${widget.movieId}_position",
      videoController.value.position.inMilliseconds,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedPosition().then((seeked) {
      setState(() {
        seekToPosition = seeked;
      });
    });

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
            autoPlay: true,
            looping: false,
            showControls: true,
            allowPlaybackSpeedChanging: false,
            fullScreenByDefault: true,
            aspectRatio: 16 / 9,
            showOptions: false,
            showSubtitles: true,
            zoomAndPan: true,
            allowedScreenSleep: false,
            allowMuting: true,
            bufferingBuilder: (_) => const CircularProgressIndicator(),
            deviceOrientationsOnEnterFullScreen: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight
            ],
            deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],

            /* materialProgressColors: ChewieProgressColors(
              playedColor: Colors.red,
              handleColor: Colors.red,
            ), */
          );
          _chewieController!.addListener(() => _savePosition(_controller));
          _chewieController!.seekTo(seekToPosition!);
          setState(() {});
        });
    } catch (ex) {
      print("waiting for url");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Chewie(controller: _chewieController!);
  }
}
