import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/ui/layout/mobile_speedslider_and_fontsize_controls.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/speed_slider_overlay.dart';
import 'package:roonmatrix/ui/layout/titlebar_info_content.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:updatable_ticker/updatable_ticker.dart';
import 'package:window_manager/window_manager.dart';

class ScrollMatrixPage extends StatefulWidget {
  final String ip;
  final String name;
  final Map<String, dynamic> translations;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final double scrollSpeed;
  final Function(double speed) speedChanged;

  const ScrollMatrixPage({
    super.key,
    required this.ip,
    required this.name,
    required this.translations,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.scrollSpeed,
    required this.speedChanged,
  });

  @override
  State<ScrollMatrixPage> createState() => _ScrollMatrixPageState();
}

class _ScrollMatrixPageState extends State<ScrollMatrixPage>
    with WindowListener {
  String get ip => widget.ip;
  String get name => widget.name;
  Map<String, dynamic> get translations => widget.translations;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  Function(double speed) get speedChanged => widget.speedChanged;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Orientation orientation = Orientation.portrait;
  Offset actualPosition = Offset(0, 0);
  Size actualSize = Size(1280, 768);
  String macosVersion = '';
  String displaystr = '';
  String scrollText = '';
  String title = '';
  double width = 1280;
  double height = 768;
  double fontSize = 64.0;
  double mobileFontSize = 64.0;
  double pixelsPerSecond = 200 + 64.0 / 2.25;
  double sliderValue = 1.0;
  double opacityLevel = 0;
  bool isFullscreen = false;

  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : ${translations['tickerPageHeaderText'] ?? 'Ticker'}';
    width = minDesktopSize.width;
    height = minDesktopSize.height;

    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    sliderValue = widget.scrollSpeed;

    if (SharedWidgets.isDesktopDevice()) {
      asynInitDesktopDevice();
    }

    windowManager.addListener(this);

    super.initState();
  }

  asynInitDesktopDevice() async {
    bool isFullscreenStatus = await windowManager.isFullScreen();
    Offset position = await windowManager.getPosition();
    Size size = await windowManager.getSize();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        setState(() {
          actualPosition = position;
          actualSize = size;
          isFullscreen = isFullscreenStatus;
        });
      }

      if (!isFullscreenStatus) {
        mainBloc.windowResizeToFullWidthAndMinimumHeight(
            minDesktopSize: minDesktopSize);
      }
    });
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() {
      isFullscreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() {
      isFullscreen = false;
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  updateSizes(String caller) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    fontSize = SharedWidgets.isDesktopDevice()
        ? height - 60 - height / 6
        : mobileFontSize;
    pixelsPerSecond = 200 + fontSize / 2.25;
    // if (kDebugMode) {
    //   debugPrint(
    //       'xxx123 ScrollMatrixPage => updateSizes, caller: $caller, width: $width, height: $height, fontSize: $fontSize');
    // }
  }

  Widget body() => SizedBox(
        width: double.infinity,
        child: RoonmatrixAnimatedGradient(
          child: BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return SizedBox();
                }

                if (mainState.devices.isNotEmpty &&
                    mainState.info.containsKey(ip)) {
                  String displaystrNew = mainState.info[ip]['app_displaystr'];

                  if (displaystrNew != displaystr) {
                    scrollText =
                        mainRepository.replaceIllegalCharsInTickerString(
                            str: displaystrNew, replaceActiveZoneMarker: true);
                    if (kDebugMode) {
                      debugPrint('==> new scrollText: $scrollText');
                    }
                  }
                }

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation o) {
                  if (o != orientation) {
                    orientation = o;
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        setState(() {
                          orientation = o;
                        });
                      }
                    });
                  }

                  return NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (notification) {
                      updateSizes('NotificationListener');
                      build(context);
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        height: height - 52,
                        child: UpdatableTicker(
                          key: ValueKey(
                              'UpdatableTickerMatrixPage${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                          updatableText: scrollText,
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: fontSize / 1.2,
                            color: Colors.black,
                          ),
                          pixelsPerSecond: pixelsPerSecond * sliderValue,
                          forceUpdate: false,
                          center: true,
                          separator: '    ////    ',
                        ),
                      ),
                    ),
                  );
                });
              }),
        ),
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (SharedWidgets.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: SharedWidgets.brightness(),
            middle: SharedWidgets.inIosStyle() ? null : Text(title),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: CupertinoNavigationBarBackButton(),
              onPressed: () => Navigator.pop(context),
            ),
            trailing: SizedBox(
              width: SharedWidgets.inIosStyle()
                  ? MediaQuery.of(context).size.width - 100
                  : 900.0,
              child: MobileSpeedSliderAndFontsizeControls(
                translations: translations,
                ip: ip,
                width: width,
                scrollSpeed: widget.scrollSpeed,
                speedChanged: (double speed) {
                  speedChanged(speed);
                  setState(() => sliderValue = speed);
                },
                sizeChanged: (double size) =>
                    setState(() => mobileFontSize = size),
              ),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                body(),
                if (SharedWidgets.isDesktopDevice())
                  Positioned(
                    bottom: -10,
                    right: 0,
                    child: SpeedSliderOverlay(
                      translations: translations,
                      width: width,
                      scrollSpeed: widget.scrollSpeed,
                      speedChanged: (double speed) {
                        speedChanged(speed);
                        setState(() {
                          sliderValue = speed;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocBuilder(
        bloc: mainBloc,
        builder: (context, MainState mainState) {
          if (mainState is! MainStateLoaded) {
            return Container();
          }

          macosVersion = mainState.macosVersion;

          return SharedWidgets.inMacosStyle()
              ? PageWithToolbarMacStyle(
                  title: title,
                  standardDesktopSize: standardDesktopSize,
                  macosVersion: macosVersion,
                  actions: [
                    CustomToolbarItem(
                      inToolbarBuilder: (context) => Padding(
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 8.0, bottom: 0.0),
                        child: TitlebarInfoContent(
                          ip: ip,
                          translations: translations,
                        ),
                      ),
                      inOverflowedBuilder: (context) =>
                          Container(color: Colors.grey, width: 30, height: 1),
                    ),
                    const ToolBarSpacer(),
                  ],
                  additionalFullscreenTitleContent: TitlebarInfoContent(
                    ip: ip,
                    translations: translations,
                  ),
                  body: Stack(
                    children: [
                      body(),
                      Positioned(
                        bottom: -10,
                        right: 0,
                        child: SpeedSliderOverlay(
                          translations: translations,
                          width: width,
                          scrollSpeed: widget.scrollSpeed,
                          speedChanged: (double speed) {
                            speedChanged(speed);
                            setState(() {
                              sliderValue = speed;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  backButtonPressed: () {
                    if (SharedWidgets.isDesktopDevice() && !isFullscreen) {
                      mainBloc.windowResize(
                          size: actualSize, position: actualPosition);
                    }
                  },
                  resizeToFullWidth: () {
                    mainBloc.windowResizeToFullWidthAndMinimumHeight(
                        minDesktopSize: minDesktopSize);
                  },
                )
              : PageWithToolbarFlutterStyle(
                  scaffoldKey: scaffoldKey,
                  title: title,
                  showExpandableSpeedSlider: false,
                  scrollSpeedDevice: 1.0,
                  standardDesktopSize: standardDesktopSize,
                  actions: [
                    if (SharedWidgets.isDesktopDevice())
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: TitlebarInfoContent(
                          ip: ip,
                          translations: translations,
                        ),
                      ),
                    if (SharedWidgets.isMobileDevice())
                      MobileSpeedSliderAndFontsizeControls(
                        translations: translations,
                        ip: ip,
                        width: width,
                        scrollSpeed: widget.scrollSpeed,
                        speedChanged: (double speed) {
                          speedChanged(speed);
                          setState(() => sliderValue = speed);
                        },
                        sizeChanged: (double size) =>
                            setState(() => mobileFontSize = size),
                      ),
                  ],
                  body: Stack(
                    children: [
                      body(),
                      if (SharedWidgets.isDesktopDevice())
                        Positioned(
                          bottom: -10,
                          right: 0,
                          child: SpeedSliderOverlay(
                            translations: translations,
                            width: width,
                            scrollSpeed: widget.scrollSpeed,
                            speedChanged: (double speed) {
                              speedChanged(speed);
                              setState(() {
                                sliderValue = speed;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  backButtonPressed: () {
                    if (SharedWidgets.isDesktopDevice() && !isFullscreen) {
                      mainBloc.windowResize(
                          size: actualSize, position: actualPosition);
                    }
                  },
                  resizeToFullWidth: () {
                    mainBloc.windowResizeToFullWidthAndMinimumHeight(
                        minDesktopSize: minDesktopSize);
                  },
                );
        });
  }
}
