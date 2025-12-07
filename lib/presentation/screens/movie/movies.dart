import 'dart:collection';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/presentation/screens/movie/customplayer.dart';
import 'package:video_player/video_player.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

Future<String?> getFullHtml(InAppWebViewController controller) async {
  String html = await controller.evaluateJavascript(
      source:
          "document.documentElement.innerHTML = document.documentElement.outerHTML;");
  Logger().d(html);
  return html;
}

enableWebDegging() async {
  await InAppWebViewController.setWebContentsDebuggingEnabled(true);
}

class _MovieScreenState extends State<MovieScreen> {
  InAppWebViewController? controller;
  bool debugEnabled = true;

  String vidUrl = "";

  @override
  Widget build(BuildContext context) {
    enableWebDegging();
    return Scaffold(
        appBar: AppBar(
          title: const Text("InAppWebView Demo"),
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
              child: CustomVideoPlayer(url: vidUrl
                  // 'https://tmstr4.thrumbleandjaxon.com/pl/H4sIAAAAAAAAAxXIy3KDIBQA0F8C8qh0V4OaMZGUK9xUdgloiYrTzqSp8es7PcvTuXXbuRXhzrfrbZK8sO4_Opcw7smWv7pn8kBSkopxWxXzs977u9_xY2XGCekoGgYHz0BpATcs5NKOsoBh01SE99CP2vXw3QyK1miDy.zlhDmeRfixWW7c2Qf3vIMaaNNqr.2IEcxcaJ0WlZBEYRBSW3Wg_nDK_RmiIyjC7RpDqVZywVV5hOFzAZJtYI.NwVHquGaw2C3m5QMzGj2ZB_vx9mhFOrkojdL.t6b5u1zS1FNk11jNlynd2.GLXm68cJPf1YZSRDQ1Df0fVAxyNCEBAAA-/master.m3u8',
                  ),
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
                          "https://vidsrc-embed.ru/embed/movie?tmdb=1084242&autoplay=1&muted=1")),
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
                    color: Theme.of(context).colorScheme.primary,
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
