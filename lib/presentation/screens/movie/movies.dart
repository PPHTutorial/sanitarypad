import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logger/logger.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/presentation/screens/movie/core/constants/tmdb_endpoints.dart';
import 'package:sanitarypad/presentation/screens/movie/customplayer.dart';
import 'package:sanitarypad/presentation/screens/movie/domain/entities/movie.dart';
import 'package:sanitarypad/presentation/screens/movie/presentation/widgets/cached_image_widget.dart';
import 'package:palette_generator/palette_generator.dart';

enum StreamState { loading, extracting, playing, error }

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key, required this.movie});
  final Movie movie;

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  InAppWebViewController? controller;
  StreamState _state = StreamState.loading;
  String _vidUrl = "";
  String _statusMessage = "Initializing secure connection...";
  Timer? _extractionTimeout;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _extractionTimeout?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _extractionTimeout?.cancel();
    _extractionTimeout = Timer(const Duration(seconds: 20), () {
      if (_state != StreamState.playing) {
        setState(() {
          _state = StreamState.error;
          _statusMessage = "Connection timed out. Please try again.";
        });
      }
    });
  }

  void _onStreamFound(String url) {
    if (_state == StreamState.playing) return;

    _extractionTimeout?.cancel();
    print("🎬 Stream found: $url");

    setState(() {
      _vidUrl = url;
      _state = StreamState.playing;
    });

    // Enter immersive mode for playback
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The WebView (Hidden but active)
          // We use Opacity 0 instead of Offstage to ensure it renders/executes JS
          Opacity(
            opacity: 0,
            child: InAppWebView(
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllowFullscreen: true,
                userAgent:
                    "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.5481.153 Mobile Safari/537.36",
              ),
              initialUrlRequest: URLRequest(
                url: WebUri(
                    "https://vidsrc-embed.ru/embed/movie?tmdb=${widget.movie.id}"),
              ),
              onWebViewCreated: (ctrl) {
                controller = ctrl;
              },
              onLoadStop: (ctrl, url) async {
                setState(() {
                  if (_state == StreamState.loading) {
                    _state = StreamState.extracting;
                    _statusMessage = "Decrypting stream...";
                  }
                });

                // Automated "Play" clicker
                // Tries to click #pl_but or any large play overlay
                await ctrl.evaluateJavascript(source: """
                  (function() {
                    console.log("[AutoPlayer] Starting auto-click sequence...");
                    
                    function clickPlay() {
                      const btn = document.querySelector("#pl_but") || document.querySelector(".play-button") || document.querySelector("button[class*='play']");
                      if(btn) {
                        console.log("[AutoPlayer] Found play button, clicking...");
                        btn.click();
                        return true;
                      }
                      return false;
                    }

                    // Attempt immediate click
                    if(!clickPlay()) {
                      // Observe for button appearance
                      const observer = new MutationObserver((mutations) => {
                        if(clickPlay()) {
                          observer.disconnect();
                        }
                      });
                      observer.observe(document.body, {childList: true, subtree: true});
                      
                      // Fallback interval
                      setInterval(clickPlay, 1000);
                    }
                  })();
                """);
              },
              shouldInterceptRequest: (controller, request) async {
                final url = request.url.toString();

                // Block devtool detection scripts
                if (url.contains("disable-devtool") ||
                    url.contains("debugger")) {
                  return WebResourceResponse(
                    contentType: "application/javascript",
                    data: Uint8List.fromList("".codeUnits),
                  );
                }
                return null;
              },
              onLoadResource: (controller, resource) {
                final url = resource.url.toString();
                if (url.contains(".m3u8") ||
                    (url.contains(".mp4") && !url.contains("preview"))) {
                  _onStreamFound(url);
                }
              },
            ),
          ),

          // 2. Loading / Status UI (When not playing)
          if (_state != StreamState.playing)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    TMDBEndpoints.posterUrl(widget.movie.posterPath!,
                        size: PosterSize.original),
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7), BlendMode.darken),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_state == StreamState.error) ...[
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _state = StreamState.loading;
                          _statusMessage = "Retrying...";
                          _startTimeoutTimer();
                        });
                        controller?.reload();
                      },
                      child: const Text("Retry"),
                    )
                  ] else ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      "$_statusMessage\nPlease wait...",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ],
              ),
            ),

          // 3. The Video Player (One playing)
          if (_state == StreamState.playing && _vidUrl.isNotEmpty)
            Positioned.fill(
              child: CustomVideoPlayer(
                url: _vidUrl,
                movieId: widget.movie.id.toString(),
              ),
            ),

          // 4. Back Button (Always visible)
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                // Reset orientation on exit
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                ]);
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
