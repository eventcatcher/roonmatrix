import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  InAppWebViewSettings inAppWebViewSettings = InAppWebViewSettings(
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

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );

    reloadDone = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
    String url,
    NavigationAction navigationAction,
  ) async {
    var uri = navigationAction.request.url!;

    if (!["http", "https", "file", "chrome", "data", "javascript", "about"]
        .contains(uri.scheme)) {
      if (await canLaunchUrl(uri)) {
        // Launch the App
        await launchUrl(
          uri,
        );
        // and cancel the request
        return NavigationActionPolicy.CANCEL;
      }
    }

    return NavigationActionPolicy.ALLOW;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        softWrap: true,
        maxLines: 3,
        title,
        style: TextStyle(fontSize: 12.0),
      )),
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
              return CircularProgressIndicator();
            }

            return SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: [
                        InAppWebView(
                          key: webViewKey,
                          webViewEnvironment: webViewEnvironment,
                          initialUrlRequest: URLRequest(
                            url: WebUri(url),
                          ),
                          initialSettings: inAppWebViewSettings,
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                          },
                          onLoadStart: (controller, myUrl) {
                            if (kDebugMode) {
                              debugPrint(
                                  'WebPageDisplay onLoadStart, url: $myUrl');
                            }
                            webPageBloc.setUrl(
                              url: myUrl.toString(),
                            );
                          },
                          // onReceivedServerTrustAuthRequest:
                          //     (controller, challenge) async {
                          //   return ServerTrustAuthResponse(
                          //       action: ServerTrustAuthResponseAction.PROCEED);
                          // },
                          onPermissionRequest: (
                            controller,
                            request,
                          ) async {
                            if (kDebugMode) {
                              debugPrint('WebPageDisplay onPermissionRequest');
                            }
                            return PermissionResponse(
                              resources: request.resources,
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                          shouldOverrideUrlLoading: (
                            controller,
                            navigationAction,
                          ) =>
                              shouldOverrideUrlLoading(
                            url,
                            navigationAction,
                          ),
                          onLoadStop: (
                            controller,
                            myUrl,
                          ) async {
                            if (kDebugMode) {
                              debugPrint('WebPageDisplay onLoadStop');
                            }
                            webPageBloc.setUrl(
                              url: myUrl.toString(),
                            );

                            if (!reloadDone &&
                                    url.toString().contains(
                                          '/login',
                                        ) ||
                                url.toString().contains(
                                      'index.html',
                                    )) {
                              if (doReload == false &&
                                  url.toString().contains(
                                        '/login',
                                      )) {
                                doReload = true;
                              }
                            }
                            if (doReload &&
                                url.toString().contains(
                                      '/contracts',
                                    )) {
                              await Future.delayed(
                                Duration(milliseconds: 2000),
                              );
                              webViewController?.reload();
                              doReload = false;
                              reloadDone = true;
                            }
                          },
                          onDidReceiveServerRedirectForProvisionalNavigation: (
                            controller,
                          ) {
                            if (kDebugMode) {
                              debugPrint(
                                  'WebPageDisplay onDidReceiveServerRedirectForProvisionalNavigation');
                            }
                          },
                          // onNavigationResponse: (
                          //   controller,
                          //   navigationResponse,
                          // ) {
                          //   print('WebPageDisplay onNavigationResponse');
                          //   return Future.value(null);
                          // },
                          onReceivedError: (
                            controller,
                            request,
                            error,
                          ) {
                            if (kDebugMode) {
                              debugPrint('WebPageDisplay onReceivedError');
                            }
                          },
                          onProgressChanged: (
                            controller,
                            myProgress,
                          ) {
                            if (kDebugMode) {
                              debugPrint('WebPageDisplay onProgressChanged');
                            }
                            webPageBloc.setProgress(
                              progress: myProgress / 100,
                            );
                          },
                          onUpdateVisitedHistory: (
                            controller,
                            myUrl,
                            androidIsReload,
                          ) {
                            webPageBloc.setUrl(
                              url: myUrl.toString(),
                            );
                            if (myUrl != null && myUrl.path == '/callback') {
                              ApproveModal(
                                context: context,
                                title: translations['spotifyLoginText'] ??
                                    "Spotify Login",
                                question:
                                    translations['spotifyConnectLoginText'] ??
                                        "Spotify Connect login was successful",
                                okText: translations['okButtonText'] ?? 'OK',
                                cancelText: '',
                                onApproved: () =>
                                    callbackUrl(url: myUrl.rawValue),
                              ).show();
                            }
                          },
                          onConsoleMessage: (
                            controller,
                            consoleMessage,
                          ) {
                            if (kDebugMode) {
                              debugPrint('WebPageDisplay onConsoleMessage');
                              debugPrint(consoleMessage.toString());
                            }
                          },
                        ),
                        progress < 1.0
                            ? LinearProgressIndicator(
                                value: progress,
                              )
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
