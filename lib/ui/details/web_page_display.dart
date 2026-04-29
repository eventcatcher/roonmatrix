import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/web_page_bloc.dart';
import 'package:roonmatrix/ui/details/web_page_state.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:url_launcher/url_launcher.dart';

class WebPageDisplay extends StatefulWidget {
  final String url;
  final String title;
  final Map<String, dynamic> translations;
  final Function({required String url}) callbackUrl;

  const WebPageDisplay({
    super.key,
    required this.url,
    required this.title,
    required this.translations,
    required this.callbackUrl,
  });

  @override
  State<WebPageDisplay> createState() => _WebPageDisplayState();
}

class _WebPageDisplayState extends State<WebPageDisplay> {
  final GlobalKey webViewKey = GlobalKey();
  final InAppWebViewSettings inAppWebViewSettings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useShouldOverrideUrlLoading: true,
    useHybridComposition: true,
    iframeAllowFullscreen: true,
  );
  final urlController = TextEditingController();

  String get title => widget.title;
  Map<String, dynamic> get translations => widget.translations;
  Function({required String url}) get callbackUrl => widget.callbackUrl;

  String url = '';
  double progress = 0;
  bool doReload = false;
  bool reloadDone = false;
  bool success = false;

  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  WebViewEnvironment? webViewEnvironment;

  late WebPageBloc webPageBloc;

  @override
  void initState() {
    super.initState();

    url = widget.url;
    webPageBloc = WebPageBloc();
    webPageBloc.loadDefaults(url: url);

    pullToRefreshController =
        kIsWeb ||
            ![
              TargetPlatform.iOS,
              TargetPlatform.android,
            ].contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(color: Colors.blue),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await webViewController?.getUrl(),
                  ),
                );
              }
            },
          );

    reloadDone = false;
  }

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
    String url,
    NavigationAction navigationAction,
  ) async {
    var uri = navigationAction.request.url!;

    if (![
      "http",
      "https",
      "file",
      "chrome",
      "data",
      "javascript",
      "about",
    ].contains(uri.scheme)) {
      if (await canLaunchUrl(uri)) {
        // Launch the App
        await launchUrl(uri);
        // and cancel the request
        return NavigationActionPolicy.CANCEL;
      }
    }

    return NavigationActionPolicy.ALLOW;
  }

  void showPageWithSuccessDialog({required String url}) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        setState(() {
          success = true;
        });
      }
    });

    ApproveModal(
      context: context,
      title: translations['spotifyLoginText'] ?? "Spotify Login",
      question:
          translations['spotifyConnectLoginText'] ??
          "Spotify Connect login was successful",
      okText: translations['okButtonText'] ?? 'OK',
      cancelText: '',
      onApproved: () => callbackUrl(url: url),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder(
        bloc: webPageBloc,
        builder: (context, WebPageState webPageState) {
          if (webPageState is WebPageStateLoaded) {
            url = webPageState.url;
            if (kDebugMode) {
              debugPrint('WebPageDisplay url: $url');
            }
            progress = webPageState.progress;
            urlController.text = url;

            if (url == '') {
              return CircularProgressIndicator(
                color: ColorDefs.blueIconColor(context: context),
              );
            }

            return SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Color(
                        Globals.brightness() == Brightness.dark
                            ? 0xFF2b2b2b
                            : 0XFFF1F5F7,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Globals.brightness() == Brightness.dark
                              ? Colors.white
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        softWrap: true,
                        maxLines: 3,
                        title,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: ColorDefs.textColor(context: context),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        success == true
                            ? Container(
                                color: Colors.green.shade800,
                                child: Center(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size:
                                          MediaQuery.of(context).size.height /
                                          3,
                                    ),
                                  ),
                                ),
                              )
                            : InAppWebView(
                                key: webViewKey,
                                webViewEnvironment: webViewEnvironment,
                                initialUrlRequest: URLRequest(url: WebUri(url)),
                                initialSettings: inAppWebViewSettings,
                                pullToRefreshController:
                                    pullToRefreshController,
                                onWebViewCreated: (controller) {
                                  webViewController = controller;
                                },
                                onLoadStart: (controller, myUrl) {
                                  if (kDebugMode) {
                                    debugPrint(
                                      'WebPageDisplay onLoadStart, url: $myUrl',
                                    );
                                  }
                                  webPageBloc.setUrl(url: myUrl.toString());
                                },
                                // onReceivedServerTrustAuthRequest:
                                //     (controller, challenge) async {
                                //   return ServerTrustAuthResponse(
                                //       action: ServerTrustAuthResponseAction.PROCEED);
                                // },
                                onPermissionRequest:
                                    (controller, request) async {
                                      if (kDebugMode) {
                                        debugPrint(
                                          'WebPageDisplay onPermissionRequest',
                                        );
                                      }
                                      return PermissionResponse(
                                        resources: request.resources,
                                        action: PermissionResponseAction.GRANT,
                                      );
                                    },
                                shouldOverrideUrlLoading:
                                    (controller, navigationAction) =>
                                        shouldOverrideUrlLoading(
                                          url,
                                          navigationAction,
                                        ),
                                onLoadStop: (controller, myUrl) async {
                                  if (kDebugMode) {
                                    debugPrint('WebPageDisplay onLoadStop');
                                  }
                                  webPageBloc.setUrl(url: myUrl.toString());

                                  if (!reloadDone &&
                                          url.toString().contains('/login') ||
                                      url.toString().contains('index.html')) {
                                    if (doReload == false &&
                                        url.toString().contains('/login')) {
                                      doReload = true;
                                    }
                                  }
                                },
                                onDidReceiveServerRedirectForProvisionalNavigation:
                                    (controller) {
                                      if (kDebugMode) {
                                        debugPrint(
                                          'WebPageDisplay onDidReceiveServerRedirectForProvisionalNavigation',
                                        );
                                      }
                                    },
                                // onNavigationResponse: (
                                //   controller,
                                //   navigationResponse,
                                // ) {
                                //   print('WebPageDisplay onNavigationResponse');
                                //   return Future.value(null);
                                // },
                                onReceivedError: (controller, request, error) {
                                  if (kDebugMode) {
                                    debugPrint(
                                      'WebPageDisplay onReceivedError',
                                    );
                                  }
                                },
                                onProgressChanged: (controller, myProgress) {
                                  if (kDebugMode) {
                                    debugPrint(
                                      'WebPageDisplay onProgressChanged',
                                    );
                                  }
                                  webPageBloc.setProgress(
                                    progress: myProgress / 100,
                                  );
                                },
                                onUpdateVisitedHistory:
                                    (controller, webUri, androidIsReload) {
                                      webPageBloc.setUrl(
                                        url: webUri.toString(),
                                      );
                                      if (webUri != null &&
                                          webUri.path == '/callback') {
                                        showPageWithSuccessDialog(
                                          url: webUri.rawValue,
                                        );
                                      }
                                    },
                                onConsoleMessage: (controller, consoleMessage) {
                                  if (kDebugMode) {
                                    debugPrint(
                                      'WebPageDisplay onConsoleMessage',
                                    );
                                    debugPrint(consoleMessage.toString());
                                  }
                                },
                              ),
                        progress < 1.0
                            ? LinearProgressIndicator(value: progress)
                            : Container(),
                      ],
                    ),
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        child: Icon(Icons.arrow_back),
                        onPressed: () {
                          webViewController?.goBack();
                        },
                      ),
                      ElevatedButton(
                        child: Icon(Icons.arrow_forward),
                        onPressed: () {
                          webViewController?.goForward();
                        },
                      ),
                      ElevatedButton(
                        child: Icon(Icons.refresh),
                        onPressed: () {
                          webViewController?.reload();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return LoadingIndicatorSmall();
        },
      ),
    );
  }
}
