// ignore_for_file: unnecessary_string_escapes


import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:sanitarypad/presentation/screens/movie/core/constants/tmdb_endpoints.dart';
import 'package:sanitarypad/presentation/screens/movie/domain/entities/movie.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({
    super.key,
    required this.movie,
    this.season,
    this.episode,
  });
  final Movie movie;
  final String? season;
  final String? episode;

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  InAppWebViewController? _controller;
  bool _streamFound = false;
  String _statusMessage = "Connecting to server...";

  String get _sourceUrl {
    if (widget.movie.mediaType == 'tv') {
      final s = widget.season ?? '1';
      final e = widget.episode ?? '1';
      return 'https://vidsrc-embed.ru/embed/tv?tmdb=${widget.movie.id}&season=$s&episode=$e';
    }
    return 'https://vidsrc-embed.ru/embed/movie?tmdb=${widget.movie.id}';
  }

  final List<String> _adDomains = [
    "google",
    "doubleclick",
    "facebook",
    "pop",
    "ads",
    "track",
    "analytics",
    "exoclick",
    "propeller",
    "juicyads",
    "adnxs",
    "adskeeper",
    "adsterra",
    "trafficjunky",
    "mgid",
    "outbrain",
    "taboola",
    "criteo",
    "bidvertiser",
    "livejasmin",
    "clickadu",
    "hilltopads",
  ];

  @override
  void initState() {
    super.initState();
  }

  String get _backgroundScript => r"""
    (function() {
      console.log("[Stream Sniffer] Extraction hooks initialized.");

      const patterns = [/\.m3u8($|\?)/i, /\.mp4($|\?)/i, /\.mpd($|\?)/i, /master\.json($|\?)/i];
      
      const notifyFound = (url) => {
        if (patterns.some(p => p.test(url))) {
           console.log("[Stream Sniffer] Intercepted: " + url);
           window.flutter_inappwebview.callHandler('onStreamFound', url);
        }
      };

      // 1. Hook XMLHttpRequest
      const originOpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function(method, url) {
        notifyFound(url);
        return originOpen.apply(this, arguments);
      };

      // 2. Hook Fetch
      const originFetch = window.fetch;
      window.fetch = function() {
        const url = (typeof arguments[0] === 'string') ? arguments[0] : (arguments[0] && arguments[0].url);
        if (url) notifyFound(url);
        return originFetch.apply(this, arguments);
      };

      // 3. Block Popups (Nuclear)
      window.open = function() {
        console.log("[Stream Sniffer] window.open blocked.");
        return null;
      };

    })();
  """;

  String get _contentScript => """
    (function() {
          // content.js
          console.log("[Stream Sniffer] Content script (Isolated) loaded.");

          function triggerEvent(element, eventType) {
              const event = new MouseEvent(eventType, {
                  view: window, bubbles: true, cancelable: true, buttons: 1
              });
              element.dispatchEvent(event);
          }

          const MAX_ATTEMPTS = 50;
          let attempts = 0;

          const clickInterval = setInterval(() => {
              try {
            /*       // 1. KNOWN AD/OVERLAYS
                  const adClose = document.querySelector('#ad720 #close');
                  if (adClose && adClose.offsetParent) {
                      console.log("[Stream Sniffer] Closing Ad.");
                      triggerEvent(adClose, 'click');
                      adClose.remove();
                  }

                  const loader = document.getElementById('loading_overlay');
                  if (loader && loader.offsetParent) {
                      console.log("[Stream Sniffer] Clicking Loader.");
                      triggerEvent(loader, 'click');
                      loader.style.display = 'none';
                  } */

                  // 2. PRIMARY TARGET: #pl_but
                  const plBut = document.getElementById('pl_but');
                  if (plBut && plBut.offsetParent) {
                      console.log("[Stream Sniffer] Clicking Primary #pl_but");
                      triggerEvent(plBut, 'click');
                      plBut.click();
                      clearInterval(clickInterval);

                      if (plBut.parentElement) {
                          triggerEvent(plBut.parentElement, 'click');
                          plBut.parentElement.click();
                          clearInterval(clickInterval);
                      }
                  }

                  /* // 3. GENERIC BACKUP
                  const candidates = [];
                  const selectors = [
                      '#pl_but_background', '.play', '.play-button', '.vjs-big-play-button',
                      'button[aria-label="Play"]'
                  ];

                  selectors.forEach(sel => {
                      document.querySelectorAll(sel).forEach(el => candidates.push(el));
                  });

                  for (let el of candidates) {
                      if (!el.offsetParent) continue;
                      if (el.id === 'pl_but') continue; 

                      console.log("[Stream Sniffer] Clicking backup:", el.className);
                      triggerEvent(el, 'click');
                      el.click();
                  }

                  attempts++;
                  if (attempts > MAX_ATTEMPTS) clearInterval(clickInterval); */

              } catch (e) {
                  console.log(e);
              }
          }, 1000);

          window.flutter_inappwebview.callHandler('onContentReady', 'initialized');
    })();
  """;

  String get _injectScript => """
    (function(){
      // inject.js
      // Runs in MAIN world.
      console.log("[Stream Sniffer] Nuclear Anti-Defense Active.");

      try {
          const noop = () => { };

          // 1. NEUTRALIZE DETECTORS (DisableDevtool)
          Object.defineProperty(window, 'DisableDevtool', {
              value: function () { return { isRunning: false, isSuspend: true }; },
              writable: false,
              configurable: false
          });

          // 2. BLOCK CLOSING & POPUPS
          window.close = function () { console.log("[Stream Sniffer] window.close blocked."); };
          window.open = function () { console.log("[Stream Sniffer] window.open blocked."); return null; };
          console.clear = function () { console.log("[Stream Sniffer] console.clear blocked."); };

          // 3. AGGRESSIVE DEBUGGER NEUTRALIZATION

          // A. Hook Function constructor (classic "debugger" check)
          const _constructor = Function.prototype.constructor;
          Function.prototype.constructor = function (string) {
              if (string && typeof string === 'string') {
                  if (string.includes('debugger')) return noop;
                  // Some use obfuscated calls
              }
              return _constructor.apply(this, arguments);
          };
          Function.prototype.constructor.prototype = _constructor.prototype;
          Function.prototype.constructor.toString = function () { return _constructor.toString(); };

          // B. Hook setInterval (async debugger loops)
          const _setInterval = window.setInterval;
          window.setInterval = function (callback, delay, ...args) {
              if (typeof callback === 'function') {
                  const code = callback.toString();
                  if (code.includes('debugger')) {
                      console.log("[Stream Sniffer] Blocked setInterval with debugger.");
                      return -1;
                  }
              } else if (typeof callback === 'string') {
                  if (callback.includes('debugger')) return -1;
              }
              return _setInterval.apply(this, arguments);
          };

          // C. Hook eval (just in case)
          const _eval = window.eval;
          window.eval = function (string) {
              if (string && string.includes('debugger')) {
                  console.log("[Stream Sniffer] Blocked eval with debugger.");
                  return noop;
              }
              return _eval.apply(this, arguments);
          };

          // 5. EVENT STOPPING
          window.addEventListener('contextmenu', (e) => e.stopImmediatePropagation(), true);

      } catch (e) {
          console.log("[Stream Sniffer] Inject Error: " + e);
      }
      
    })();
  """;

  /// Called when a valid stream URL is intercepted.
  void _onStreamExtracted(String url) {
    if (_streamFound) return;
    _streamFound = true;

    print("🎬 Stream URL extracted: $url");
    _controller?.stopLoading(); // Stop resource usage immediately

    // Use Future.microtask to ensure we don't navigate during a build phase
    // or while the navigator is locked by another transition (like back press)
    Future.microtask(() {
      if (!mounted) return;
      context.pushReplacementNamed(
        'movie-player',
        extra: {
          'url': url,
          'movieId': widget.movie.id.toString(),
          'movie': widget.movie,
          'episodes': widget.movie.episodes,
          'currentEpisode': {
            'season': int.tryParse(widget.season ?? '1'),
            'episode': int.tryParse(widget.episode ?? '1'),
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🎬 Stream Poster URL extracted: ${widget.movie.posterPath}");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_sourceUrl)),
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(
                  source: _backgroundScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
                UserScript(
                  source: _contentScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  forMainFrameOnly: false, // Run in iframes too
                ),
                /* UserScript(
                  source: _injectScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
                */
              ]),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllowFullscreen: true,
                userAgent:
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
              ),
              onWebViewCreated: (controller) {
                _controller = controller;

                // Set up the JS handler for 'onStreamFound'
                controller.addJavaScriptHandler(
                  handlerName: 'onStreamFound',
                  callback: (args) {
                    if (args.isNotEmpty) {
                      _onStreamExtracted(args[0].toString());
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'onContentReady',
                  callback: (args) {
                    debugPrint("💻 [Content] Status: ${args[0]}");
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() => _statusMessage = "Loading player...");
              },
              onLoadStop: (controller, url) {
                setState(() => _statusMessage = "Scanning for stream...");
              },
              onLoadError: (controller, url, error, description) {
                setState(() => _statusMessage = "Error: $description");
              },
              /* shouldOverrideUrlLoading: (controller, navigationAction) async {
                if (navigationAction.isForMainFrame == false) {
                  return NavigationActionPolicy.CANCEL;
                }
                final url =
                    navigationAction.request.url.toString().toLowerCase();
                for (final d in _adDomains) {
                  if (url.contains(d)) return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              shouldInterceptRequest: (controller, request) async {
                final url = request.url.toString().toLowerCase();
                for (final d in _adDomains) {
                  if (url.contains(d)) {
                    return WebResourceResponse(
                        contentType: "text/plain",
                        data: Uint8List.fromList("".codeUnits));
                  }
                }
                return null;
              }, */
              onLoadResource: (controller, resource) {
                final url = resource.url.toString();
                final patterns = [
                  RegExp(r'\.m3u8($|\?)', caseSensitive: false),
                  RegExp(r'\.mp4($|\?)', caseSensitive: false),
                  RegExp(r'\.mpd($|\?)', caseSensitive: false),
                ];

                if (patterns.any((p) => p.hasMatch(url))) {
                  if (!url.contains("segment") && !url.contains("ad")) {
                    _onStreamExtracted(url);
                  }
                }
              },
              onConsoleMessage: (controller, consoleMessage) {
                if (consoleMessage.message
                    .contains("[Stream Sniffer] Intercepted:")) {
                  debugPrint(
                      "[Stream Sniffer] Intercepted flutter: ${consoleMessage.message}");
                }
              },
            ),
          ),

          // 2. Loading UI
          Positioned.fill(
            child: widget.movie.posterPath != null
                ? Container(
                    color: Colors.black,
                    child: CachedNetworkImage(
                      imageUrl: TMDBEndpoints.posterUrl(widget.movie.posterPath!,
                          size: PosterSize.original),
                      fit: BoxFit.cover,
                    ),
                )
                : Container(
                    color: Colors.black,
                  ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.pinkAccent),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.movie.title,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Back Button
          Positioned(
            top: 25,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
