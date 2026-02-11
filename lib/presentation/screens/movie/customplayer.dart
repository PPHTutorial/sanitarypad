// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../services/credit_manager.dart';
import 'package:go_router/go_router.dart';
import 'domain/entities/movie.dart';
import 'presentation/providers/favorites_provider.dart';

/// Netflix-style video player with embedded stream extraction and seamless episode switching.
class CustomVideoPlayer extends ConsumerStatefulWidget {
  final String url;
  final String movieId;
  final Movie? sourceMovie;
  final List<Map<String, dynamic>>? episodes;
  final Map<String, dynamic>? currentEpisode;

  const CustomVideoPlayer({
    super.key,
    required this.url,
    required this.movieId,
    this.sourceMovie,
    this.episodes,
    this.currentEpisode,
  });

  @override
  ConsumerState<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends ConsumerState<CustomVideoPlayer> {
  // -- Player Controllers --
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;
  String _currentStreamUrl = '';

  // -- Currently Playing Episode (mutable) --
  late int _currentSeason;
  late int _currentEpisodeNum;

  // -- In-Player Extraction State --
  bool _isLoadingNewStream = false; // Shows overlay during episode switch
  String? _preloadedNextEpisodeUrl;
  HeadlessInAppWebView? _headlessWebView;
  Completer<String?>? _extractionCompleter;

  // -- VLC/Netflix-style overlays --
  String? _overlayText;
  IconData? _overlayIcon;
  Timer? _overlayTimer;

  // -- Premium Features --
  bool _isLocked = false;
  double _volume = 1.0;
  bool _showCustomControls = true;
  Timer? _hideControlsTimer;
  Timer? _creditDeductionTimer;
  Timer? _watchNextTimer;

  // -- Auto-play State --
  bool _showWatchNextOverlay = false;
  int _watchNextCountdown = 10;
  bool _isAutoPlaying = false;
  final int _watchNextThresholdSeconds = 120; // 2 minutes

  // -- Scripts (copied from movies.dart) --
  static const String _extractionScript = r"""
    (function() {
      console.log("[Stream Sniffer] Extraction hooks initialized.");
      const patterns = [/\.m3u8($|\?)/i, /\.mp4($|\?)/i, /\.mpd($|\?)/i];
      const notifyFound = (url) => {
        if (patterns.some(p => p.test(url))) {
           console.log("[Stream Sniffer] Intercepted: " + url);
           window.flutter_inappwebview.callHandler('onStreamFound', url);
        }
      };
      const originOpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function(method, url) {
        notifyFound(url);
        return originOpen.apply(this, arguments);
      };
      const originFetch = window.fetch;
      window.fetch = function() {
        const url = (typeof arguments[0] === 'string') ? arguments[0] : (arguments[0] && arguments[0].url);
        if (url) notifyFound(url);
        return originFetch.apply(this, arguments);
      };
      window.open = function() { return null; };
    })();
  """;

  static const String _autoClickScript = r"""
    (function() {
      function triggerEvent(element, eventType) {
          const event = new MouseEvent(eventType, { view: window, bubbles: true, cancelable: true, buttons: 1 });
          element.dispatchEvent(event);
      }
      const clickInterval = setInterval(() => {
          try {
              const plBut = document.getElementById('pl_but');
              if (plBut && plBut.offsetParent) {
                  console.log("[Stream Sniffer] Clicking #pl_but");
                  triggerEvent(plBut, 'click');
                  plBut.click();
                  clearInterval(clickInterval);
                  if (plBut.parentElement) {
                      triggerEvent(plBut.parentElement, 'click');
                  }
              }
          } catch (e) { console.log(e); }
      }, 1000);
      window.flutter_inappwebview.callHandler('onContentReady', 'initialized');
    })();
  """;

  @override
  void initState() {
    super.initState();
    _currentStreamUrl = widget.url;
    _currentSeason = widget.currentEpisode?['season'] as int? ?? 1;
    _currentEpisodeNum = widget.currentEpisode?['episode'] as int? ?? 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer(_currentStreamUrl);
      _startCreditDeductionTimer();
      _preloadNextEpisode();
    });
  }

  // ============================================================================
  // POSITION STORAGE (Per-Episode for TV)
  // ============================================================================
  String get _positionKey {
    if (widget.sourceMovie?.mediaType == 'tv') {
      return 'movie_${widget.movieId}_S${_currentSeason}_E${_currentEpisodeNum}_position';
    }
    return 'movie_${widget.movieId}_position';
  }

  Future<void> _savePosition() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    try {
      final position = _videoController!.value.position.inMilliseconds;
      if (position > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_positionKey, position);
        print('💾 Saved position ($position ms) to: $_positionKey');
      }
    } catch (e) {
      debugPrint("Error saving position: $e");
    }
  }

  Future<Duration> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMs = prefs.getInt(_positionKey) ?? 0;
    print('🔄 Loaded position ($savedMs ms) from: $_positionKey');
    return Duration(milliseconds: savedMs);
  }

  // ============================================================================
  // CREDIT DEDUCTION (Resets on each new episode)
  // ============================================================================
  void _startCreditDeductionTimer() {
    _creditDeductionTimer?.cancel();
    _creditDeductionTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted) return;

      // Request credit - shows ad dialog if insufficient
      final hasCredit = await ref
          .read(creditManagerProvider)
          .requestCredit(context, ActionType.movie);

      if (hasCredit) {
        debugPrint(
            "🎬 30s Playback: Credit Consumed for S$_currentSeason E$_currentEpisodeNum");
      } else {
        // User refused to watch ad or has no credits - go home
        debugPrint("🎬 Credit refused - navigating to home");
        if (mounted) {
          // Restore orientation and system UI before leaving
          await SystemChrome.setPreferredOrientations(
              [DeviceOrientation.portraitUp]);
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          context.go('/'); // Navigate to home
        }
      }
    });
  }

  // ============================================================================
  // PLAYER INITIALIZATION
  // ============================================================================
  Future<void> _initializePlayer(String streamUrl) async {
    try {
      final startPosition = await _loadPosition();

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true, allowBackgroundPlayback: false),
      );

      await _videoController!.initialize();
      _volume = _videoController!.value.volume;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        startAt: startPosition,
        showControls: false,
        allowPlaybackSpeedChanging: true,
        fullScreenByDefault: false,
        allowFullScreen: false,
        zoomAndPan: true,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(color: Colors.black),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) =>
            _buildErrorWidget(errorMessage),
        allowedScreenSleep: false,
      );

      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      if (mounted) {
        setState(() => _isInitialized = true);
        _startHideTimer();
        _addProgressListener();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text("Stream Blocked or Expired",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _retryCurrentEpisode,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADLESS WEBVIEW STREAM EXTRACTION
  // ============================================================================
  Future<String?> _extractStreamUrl(
      {required int season, required int episode}) async {
    if (widget.sourceMovie == null) return null;

    final tmdbId = widget.sourceMovie!.id;
    final isTv = widget.sourceMovie!.mediaType == 'tv';
    final targetUrl = isTv
        ? 'https://vidsrc-embed.ru/embed/tv?tmdb=$tmdbId&season=$season&episode=$episode'
        : 'https://vidsrc-embed.ru/embed/movie?tmdb=$tmdbId';

    print('🌐 Starting headless extraction for: $targetUrl');

    _extractionCompleter = Completer<String?>();
    String? foundUrl;

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
            source: _extractionScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
        UserScript(
            source: _autoClickScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            forMainFrameOnly: false),
      ]),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        userAgent:
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      ),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'onStreamFound',
          callback: (args) {
            if (args.isNotEmpty && !_extractionCompleter!.isCompleted) {
              foundUrl = args[0].toString();
              print('✅ Stream extracted: $foundUrl');
              _extractionCompleter!.complete(foundUrl);
            }
          },
        );
      },
      onLoadResource: (controller, resource) {
        final url = resource.url.toString();
        final patterns = [
          RegExp(r'\.m3u8($|\?)', caseSensitive: false),
          RegExp(r'\.mp4($|\?)', caseSensitive: false)
        ];
        if (patterns.any((p) => p.hasMatch(url)) &&
            !url.contains("segment") &&
            !url.contains("ad")) {
          if (!_extractionCompleter!.isCompleted) {
            foundUrl = url;
            print('✅ Stream from resource: $foundUrl');
            _extractionCompleter!.complete(foundUrl);
          }
        }
      },
    );

    await _headlessWebView!.run();

    // Timeout after 30 seconds
    final result = await _extractionCompleter!.future
        .timeout(const Duration(seconds: 30), onTimeout: () {
      print('⏳ Extraction timed out.');
      return null;
    });

    await _headlessWebView?.dispose();
    _headlessWebView = null;

    return result;
  }

  // ============================================================================
  // PRELOAD NEXT EPISODE
  // ============================================================================
  Future<void> _preloadNextEpisode() async {
    if (widget.episodes == null || widget.episodes!.isEmpty) return;
    if (widget.sourceMovie?.mediaType != 'tv') return;

    final nextEpIndex = widget.episodes!.indexWhere((e) =>
        e['season'] == _currentSeason &&
        e['episode'] == _currentEpisodeNum + 1);
    if (nextEpIndex == -1) {
      print('ℹ️ No next episode to preload.');
      return;
    }

    final nextEp = widget.episodes![nextEpIndex];
    print(
        '🔮 Pre-loading next episode: S${nextEp['season']} E${nextEp['episode']}');

    final url = await _extractStreamUrl(
        season: nextEp['season'] as int, episode: nextEp['episode'] as int);
    if (url != null) {
      _preloadedNextEpisodeUrl = url;
      print('🎉 Next episode pre-loaded!');
    }
  }

  // ============================================================================
  // SWITCH TO EPISODE (Seamless, In-Player)
  // ============================================================================
  Future<void> _switchToEpisode(Map<String, dynamic> episode) async {
    final targetSeason = episode['season'] as int;
    final targetEpisode = episode['episode'] as int;

    if (targetSeason == _currentSeason && targetEpisode == _currentEpisodeNum) {
      return; // Already playing
    }

    print('🔄 Switching to S$targetSeason E$targetEpisode');

    // 1. Save current position
    await _savePosition();

    // 2. Show loading state
    setState(() => _isLoadingNewStream = true);

    // 3. Determine if we have preloaded URL
    String? newUrl;
    final isNextEpisode = targetSeason == _currentSeason &&
        targetEpisode == _currentEpisodeNum + 1;

    if (isNextEpisode && _preloadedNextEpisodeUrl != null) {
      newUrl = _preloadedNextEpisodeUrl;
      _preloadedNextEpisodeUrl = null; // Consume it
      print('⚡ Using pre-loaded URL!');
    } else {
      newUrl =
          await _extractStreamUrl(season: targetSeason, episode: targetEpisode);
    }

    if (newUrl == null) {
      setState(() {
        _isLoadingNewStream = false;
        _errorMessage =
            'Failed to extract stream for S$targetSeason E$targetEpisode';
      });
      return;
    }

    // 4. Dispose old controllers
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;

    // 5. Update state
    _currentSeason = targetSeason;
    _currentEpisodeNum = targetEpisode;
    _currentStreamUrl = newUrl;
    _isInitialized = false;
    _errorMessage = null;

    // 6. Initialize new player
    await _initializePlayer(newUrl);

    // 7. Reset credit timer
    _startCreditDeductionTimer();

    // 8. Hide loading
    setState(() => _isLoadingNewStream = false);

    // 9. Preload the *new* next episode
    _preloadNextEpisode();
  }

  void _skipToNext() {
    if (widget.episodes == null || widget.episodes!.isEmpty) return;
    final nextEpIndex = widget.episodes!.indexWhere((e) =>
        e['season'] == _currentSeason &&
        e['episode'] == _currentEpisodeNum + 1);

    if (nextEpIndex != -1) {
      _switchToEpisode(widget.episodes![nextEpIndex]);
      _showOverlay("Next Episode", Icons.skip_next);
    } else {
      _showOverlay("No Next Episode", Icons.error_outline);
    }
  }

  void _skipToPrev() {
    if (widget.episodes == null || widget.episodes!.isEmpty) return;
    final prevEpIndex = widget.episodes!.indexWhere((e) =>
        e['season'] == _currentSeason &&
        e['episode'] == _currentEpisodeNum - 1);

    if (prevEpIndex != -1) {
      _switchToEpisode(widget.episodes![prevEpIndex]);
      _showOverlay("Previous Episode", Icons.skip_previous);
    } else {
      _showOverlay("No Previous Episode", Icons.error_outline);
    }
  }

  void _retryCurrentEpisode() async {
    setState(() {
      _errorMessage = null;
      _isLoadingNewStream = true;
    });
    final url = await _extractStreamUrl(
        season: _currentSeason, episode: _currentEpisodeNum);
    if (url != null) {
      _currentStreamUrl = url;
      await _initializePlayer(url);
    } else {
      setState(() => _errorMessage = 'Retry failed. Please try again.');
    }
    setState(() => _isLoadingNewStream = false);
  }

  // ============================================================================
  // PROGRESS MONITORING & AUTO-PLAY
  // ============================================================================
  void _addProgressListener() {
    _videoController?.addListener(_onProgressChanged);
  }

  void _onProgressChanged() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final duration = _videoController!.value.duration;
    final position = _videoController!.value.position;
    final remaining = duration - position;

    // Trigger "Watch Next" 2 minutes before end
    if (widget.episodes != null &&
        widget.episodes!.isNotEmpty &&
        widget.sourceMovie?.mediaType == 'tv' &&
        remaining.inSeconds <= _watchNextThresholdSeconds &&
        remaining.inSeconds > 0 &&
        !_showWatchNextOverlay &&
        !_isAutoPlaying) {
      _triggerWatchNext();
    }

    // Auto-play when video ends
    if (position >= duration && duration.inSeconds > 0 && !_isAutoPlaying) {
      _onVideoEnded();
    }
  }

  void _triggerWatchNext() {
    final nextEpIndex = widget.episodes!.indexWhere((e) =>
        e['season'] == _currentSeason &&
        e['episode'] == _currentEpisodeNum + 1);

    if (nextEpIndex != -1) {
      setState(() {
        _showWatchNextOverlay = true;
        _watchNextCountdown = 10;
      });
      _startWatchNextCountdown();
    }
  }

  void _startWatchNextCountdown() {
    _watchNextTimer?.cancel();
    _watchNextTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_watchNextCountdown > 0) {
        setState(() => _watchNextCountdown--);
      } else {
        timer.cancel();
        _onWatchNextConfirmed();
      }
    });
  }

  void _onWatchNextConfirmed() {
    if (_showWatchNextOverlay) {
      setState(() {
        _showWatchNextOverlay = false;
        _isAutoPlaying = true;
      });
      final nextEpIndex = widget.episodes!.indexWhere((e) =>
          e['season'] == _currentSeason &&
          e['episode'] == _currentEpisodeNum + 1);
      if (nextEpIndex != -1) {
        _switchToEpisode(widget.episodes![nextEpIndex]);
      }
    }
  }

  void _onVideoEnded() {
    setState(() => _isAutoPlaying = true);
    final nextEpIndex = widget.episodes!.indexWhere((e) =>
        e['season'] == _currentSeason &&
        e['episode'] == _currentEpisodeNum + 1);
    if (nextEpIndex != -1) {
      _switchToEpisode(widget.episodes![nextEpIndex]);
    } else {
      // Last episode of the series or movie finished
      Navigator.of(context).pop();
    }
  }

  void _cancelWatchNext() {
    _watchNextTimer?.cancel();
    setState(() => _showWatchNextOverlay = false);
  }

  // ============================================================================
  // UI CONTROLS
  // ============================================================================
  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          _videoController != null &&
          _videoController!.value.isPlaying) {
        setState(() => _showCustomControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showCustomControls = !_showCustomControls);
    if (_showCustomControls) _startHideTimer();
  }

  void _showOverlay(String text, IconData icon) {
    if (!mounted) return;
    setState(() {
      _overlayText = text;
      _overlayIcon = icon;
    });
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _overlayText = null;
          _overlayIcon = null;
        });
      }
    });
  }

  void _seek(bool forward) async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final currentPos = _videoController!.value.position;
    final newPos = forward
        ? currentPos + const Duration(seconds: 10)
        : currentPos - const Duration(seconds: 10);
    await _videoController!.seekTo(newPos);
    _showOverlay(forward ? "+10s" : "-10s",
        forward ? Icons.fast_forward : Icons.fast_rewind);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showEpisodeList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    "${widget.sourceMovie?.title ?? ""} - ${widget.currentEpisode!["season"]}Episodes",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.episodes?.length ?? 0,
                itemBuilder: (context, index) {
                  final ep = widget.episodes![index];
                  final isCurrent = ep['episode'] == _currentEpisodeNum &&
                      ep['season'] == _currentSeason;
                  return ListTile(
                    leading: Icon(Icons.movie, color: Colors.white70),
                    title: Text("Episode ${ep['episode']}",
                        style: TextStyle(
                            color: isCurrent ? Colors.pinkAccent : Colors.white,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    //subtitle: Text("Season ${ep['season']}",
                    //  style: const TextStyle(color: Colors.white70)),
                    trailing: isCurrent
                        ? const Icon(Icons.play_circle_outline,
                            color: Colors.pinkAccent)
                        : const Icon(Icons.play_arrow, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isCurrent) _switchToEpisode(ep);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _savePosition();
    _overlayTimer?.cancel();
    _hideControlsTimer?.cancel();
    _creditDeductionTimer?.cancel();
    _watchNextTimer?.cancel();
    _headlessWebView?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    // Error State
    if (_errorMessage != null && !_isLoadingNewStream) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: _buildErrorWidget(_errorMessage!));
    }

    // Loading State (initial or switching)
    if (!_isInitialized || _chewieController == null || _isLoadingNewStream) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.pinkAccent),
              const SizedBox(height: 24),
              Text(
                _isLoadingNewStream
                    ? "Loading Episode S$_currentSeason E$_currentEpisodeNum..."
                    : "Preparing Player...",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (widget.sourceMovie != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(widget.sourceMovie!.title,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ),
            ],
          ),
        ),
      );
    }

    // Player UI
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragUpdate: (details) {
          if (_isLocked) return;
          final height = MediaQuery.of(context).size.height;
          final delta = details.primaryDelta! / height;
          if (details.localPosition.dx <
              MediaQuery.of(context).size.width / 2) {
            // Brightness (Left side) - placeholder
          } else {
            setState(() {
              _volume = (_volume - delta).clamp(0.0, 1.0);
              _videoController?.setVolume(_volume);
            });
            _showOverlay("${(_volume * 100).toInt()}%", Icons.volume_up);
          }
        },
        child: Stack(
          children: [
            // 1. The Player
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),

            // 2. Controls Layer
            if (_showCustomControls) _buildControlsOverlay(),

            // 3. VLC Style Overlay
            if (_overlayIcon != null) _buildVlcOverlay(),

            // 4. Watch Next Overlay (Netflix Style)
            if (_showWatchNextOverlay) _buildWatchNextOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchNextOverlay() {
    return Positioned(
      bottom: 100,
      right: 32,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 320,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Up Next",
                    style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: _cancelWatchNext,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    image: widget.sourceMovie?.posterPath != null
                        ? DecorationImage(
                            image: NetworkImage(
                                "https://image.tmdb.org/t/p/w200${widget.sourceMovie!.posterPath}"),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Episode ${_currentEpisodeNum + 1}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text("Starts in ${_watchNextCountdown}s",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _onWatchNextConfirmed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Play Now",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black26,
        child: Column(
          children: [
            // Top Bar
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (!_isLocked)
                      IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop()),
                    Expanded(
                      child: Text(
                        widget.sourceMovie?.mediaType == 'tv'
                            ? "${widget.sourceMovie?.title ?? ""} - S$_currentSeason E$_currentEpisodeNum"
                            : widget.sourceMovie?.title ?? "",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.episodes != null && widget.episodes!.isNotEmpty)
                      IconButton(
                          icon: const Icon(Icons.playlist_play,
                              color: Colors.white, size: 32),
                          onPressed: _showEpisodeList),
                    if (widget.sourceMovie != null)
                      Consumer(
                        builder: (context, ref, child) {
                          final isFavorite = ref.watch(
                              isFavoriteProvider(widget.sourceMovie!.id));
                          return IconButton(
                            icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? Colors.pinkAccent
                                    : Colors.white),
                            onPressed: () {
                              ref
                                  .read(favoritesProviders.notifier)
                                  .toggleFavorite(widget.sourceMovie!);
                              _showOverlay(
                                  isFavorite
                                      ? "Removed from Favorites"
                                      : "Added to Favorites",
                                  isFavorite
                                      ? Icons.favorite_border
                                      : Icons.favorite);
                            },
                          );
                        },
                      ),
                    IconButton(
                        icon: Icon(_isLocked ? Icons.lock : Icons.lock_open,
                            color: Colors.white),
                        onPressed: () {
                          setState(() => _isLocked = !_isLocked);
                          _showOverlay(
                              _isLocked ? "Screen Locked" : "Screen Unlocked",
                              _isLocked ? Icons.lock : Icons.lock_open);
                          if (!_isLocked) _startHideTimer();
                        }),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Center Play/Pause & Seeks
            if (!_isLocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prev Episode (only for series)
                  if (widget.episodes != null && widget.episodes!.isNotEmpty)
                    _buildNavButton(Icons.skip_previous, _skipToPrev),
                  const SizedBox(width: 24),
                  IconButton(
                      icon: const Icon(Icons.replay_10,
                          color: Colors.white, size: 42),
                      onPressed: () => _seek(false)),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 88),
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                      if (_videoController!.value.isPlaying) _startHideTimer();
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                      icon: const Icon(Icons.forward_10,
                          color: Colors.white, size: 42),
                      onPressed: () => _seek(true)),
                  const SizedBox(width: 24),
                  // Next Episode (only for series)
                  if (widget.episodes != null && widget.episodes!.isNotEmpty)
                    _buildNavButton(Icons.skip_next, _skipToNext),
                ],
              ),
            const Spacer(),
            // Bottom Progress Bar
            if (!_isLocked)
              SafeArea(
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(_videoController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                              playedColor: Colors.pinkAccent,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _videoController!,
                              builder: (_, value, __) => Text(
                                  _formatDuration(value.position),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12))),
                          ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _videoController!,
                              builder: (_, value, __) => Text(
                                  _formatDuration(value.duration),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildVlcOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_overlayIcon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(_overlayText!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
