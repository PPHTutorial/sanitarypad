import 'dart:async';
import 'dart:convert';

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

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key, required this.movie});
  final Movie movie;

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

Future<String?> getFullHtml(InAppWebViewController controller) async {
  Map<dynamic, dynamic> html =
      await controller.evaluateJavascript(source: "document.body;");
  debugPrint(jsonEncode(html));
  return (jsonEncode(html));
}

enableWebDegging() async {
  await InAppWebViewController.setWebContentsDebuggingEnabled(true);
}

Future<void> updateStatusBarBrightness(ImageProvider image) async {
  final palette = await PaletteGenerator.fromImageProvider(
    image,
    size: const Size(200, 100), // speed optimization
  );

  final brightness = palette.dominantColor?.color.computeLuminance();

  print("Brightness: $brightness");

  if (brightness == null) return;

  SystemChrome.setSystemUIOverlayStyle(
    brightness > 0.5
        ? SystemUiOverlayStyle.light // dark background -> light icons
        : SystemUiOverlayStyle.dark, // light background -> dark icons
  );
}

class _MovieScreenState extends State<MovieScreen> {
  InAppWebViewController? controller;
  bool debugEnabled = true;

  String vidUrl = "";

  @override
  void initState() {
    super.initState();
    _loadAndCalculateBrightness();
  }

  Future<void> _loadAndCalculateBrightness() async {
    final image = NetworkImage(
      TMDBEndpoints.posterUrl(
        widget.movie.posterPath!,
        size: PosterSize.w780,
      ),
    );

    // REQUIRED for NetworkImage — force full load in memory
    const config = ImageConfiguration();
    final Completer<void> completer = Completer();

    final listener = ImageStreamListener((_, __) {
      completer.complete();
    });

    final stream = image.resolve(config);
    stream.addListener(listener);

    await completer.future;
    stream.removeListener(listener);

    // NOW SAFE TO USE palette generator
    updateStatusBarBrightness(image);
  }

  @override
  Widget build(BuildContext context) {
    updateStatusBarBrightness(NetworkImage(TMDBEndpoints.posterUrl(
        widget.movie.posterPath!,
        size: PosterSize.w780)));

    enableWebDegging();
    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(widget.movie.title),
          actions: [
            ActionIcons(
              icon: Icons.list,
              action: () => getFullHtml(controller!),
              controller: controller,
            ),
            ResponsiveConfig.widthBox(10),
            ActionIcons(
              icon: Icons.developer_board,
              action: () async => {
                await controller?.evaluateJavascript(source: """
                    (function() {
                      document.querySelector("#pl_but").click()                                              
                    })();
                  """)
              },
              controller: controller,
            ),
            ResponsiveConfig.widthBox(10)
          ],
        ),
        body: Column(children: [
          if (vidUrl.isNotEmpty)
            Expanded(
              child: CustomVideoPlayer(
                  url: vidUrl, movieId: widget.movie.id.toString()),
            ),
          if (vidUrl == "")
            Expanded(
              child: Stack(children: [
                InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    disableContextMenu: false,
                    javaScriptCanOpenWindowsAutomatically: true,
                    useShouldOverrideUrlLoading: true,
                  ),
                  initialUrlRequest: URLRequest(
                      url: WebUri(
                          "https://vidsrc-embed.ru/embed/movie?tmdb=${widget.movie.id}")),
                  onWebViewCreated: (ctrl) => {
                    controller?.addJavaScriptHandler(
                      handlerName: "elementTapped",
                      callback: (args) {
                        print("Element tapped:");
                        print(args[0]); // contains element data
                      },
                    ),
                    controller?.addJavaScriptHandler(
                      handlerName: 'simulateClick',
                      callback: (args) {
                        final dx = args[0];
                        final dy = args[1];
                        controller?.evaluateJavascript(source: """
                        (function() {
                          const el = document.elementFromPoint($dx, $dy);
                          if(el) {
                            const ev = new MouseEvent('click', {bubbles:true, cancelable:true, clientX:$dx, clientY:$dy});
                            el.dispatchEvent(ev);
                          }
                        })();
                      """);
                      },
                    ),
                    controller = ctrl
                  },
                  onConsoleMessage: (ctrl, msg) =>
                      print("JS LOG: ${msg.message}"),
                  onEnterFullscreen: (controller) async {
                    debugPrint("🌕 Entered fullscreen!");
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                    await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersiveSticky);
                  },
                  onExitFullscreen: (controller) async {
                    debugPrint("🌑 Exited fullscreen!");
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                    await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge);
                  },
                  shouldInterceptRequest: (controller, request) async {
                    final url = request.url.toString();

                    if (url.contains("disable-devtool")) {
                      print("Blocking disable-devtool…");

                      // Return an empty JS file to neutralize it
                      return WebResourceResponse(
                        contentType: "application/javascript",
                        data: Uint8List.fromList("".codeUnits),
                      );
                    }

                    return null;
                  },
                  onLoadStop: (controller, url) async {},
                  onLoadResource: (controller, resource) {
                    if (resource.url.toString().contains(".m3u8") ||
                        resource.url.toString().contains(".mp4")) {
                      setState(() {
                        vidUrl = resource.url.toString();
                      });
                      print("Streaming resource: ${resource.url}");
                    }
                  },
                ),
                IgnorePointer(
                  child: Container(
                    height: ResponsiveConfig.screenHeight,
                    width: ResponsiveConfig.screenWidth,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    child: CachedImageWidget(
                      imageUrl: TMDBEndpoints.posterUrl(
                        widget.movie.posterPath!,
                        size: PosterSize.w780,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              ]),
            ),
        ]));
  }
}

class ActionIcons extends StatelessWidget {
  const ActionIcons(
      {super.key, this.controller, required this.action, required this.icon});
  final InAppWebViewController? controller;
  final VoidCallback action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: action, child: Icon(icon));
  }
}
