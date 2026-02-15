import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/mobile_speed_slider_and_fontsize_controls.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/slider_hover_overlay.dart';
import 'package:roonmatrix/ui/layout/titlebar_info_content.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:updatable_ticker/updatable_ticker.dart';
import 'package:updatable_vertical_ticker/updatable_vertical_ticker.dart';
import 'package:window_manager/window_manager.dart';

class ScrollMatrixPage extends StatefulWidget {
  final String ip;
  final String name;
  final Map<String, dynamic> translations;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final double scrollSpeed;
  final bool verticalTickerActive;
  final bool ledTickerOnTickerPageActive;
  final Function(double speed) speedChanged;

  const ScrollMatrixPage({
    super.key,
    required this.ip,
    required this.name,
    required this.translations,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.scrollSpeed,
    required this.verticalTickerActive,
    required this.ledTickerOnTickerPageActive,
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
  bool get verticalTickerActive => widget.verticalTickerActive;
  bool get ledTickerOnTickerPageActive => widget.ledTickerOnTickerPageActive;
  Function(double speed) get speedChanged => widget.speedChanged;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final double sliderOverlayMaxWidth = 300.0;

  final int cyclePause = 2;

  double ledSize = 3.0;
  final double ledGap = 0.2;
  final Color ledOnColor = Colors.red.shade400;
  final Color ledOffColor = const Color(0xFF000000);
  final double ledTickerPadding = 2.0;
  final double ledTickerBorderSize = 1.0;

  Orientation orientation = Orientation.portrait;
  Offset actualPosition = Offset(0, 0);
  Size actualSize = Size(1280, 768);
  List<String> verticalTextLines = [];
  String macosVersion = '';
  String displaystr = '';
  String scrollText = '';
  String title = '';
  double width = 1280;
  double height = 768;
  double fontSize = 1.0;
  double mobileFontSize = 1.0;
  double pixelsPerSecond = 0;
  double sliderValue = 1.0;
  int scrollDuration = 0;
  int linePause = 0;
  int ledModules = 9;
  bool isFullscreen = false;
  bool verticalOutput = false;
  bool fontSizeInitialized = false;

  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : ${translations['tickerPageHeaderText'] ?? 'Ticker'}';
    pixelsPerSecond = getPixelsPerSecond(fontSize: fontSize);
    width = minDesktopSize.width;
    height = minDesktopSize.height;

    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    sliderValue = widget.scrollSpeed;

    if (Globals.isDesktopDevice()) {
      asynInitDesktopDevice();
    }

    windowManager.addListener(this);

    super.initState();
  }

  Future<void> asynInitDesktopDevice() async {
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

  getPixelsPerSecond({required double fontSize}) =>
      pixelsPerSecond = 200 + fontSize / 2.25;

  void initMobileFontSize() {
    if (Globals.isMobileDevice()) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          setState(() {
            if (verticalOutput && verticalTickerActive) {
              width = MediaQuery.of(context).size.width;
              height = MediaQuery.of(context).size.height;
              mobileFontSize =
                  width / ledModules / Globals.verticalTickerWidthFactor;
            } else {
              mobileFontSize = Globals.mobileFontSizeMedium;
            }
            fontSize = mobileFontSize;
            pixelsPerSecond = getPixelsPerSecond(fontSize: fontSize);
          });
        }
      });
    }
  }

  void updateSizes(String caller) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    if (Globals.isDesktopDevice()) {
      if (verticalOutput && verticalTickerActive) {
        double maxFontSizeForWidth =
            width / ledModules / Globals.verticalTickerWidthFactor;
        ledSize = width / ledModules / 1.0 / 8;
        double maxFontSizeForHeight = height - 60 - height / 6;
        fontSize = maxFontSizeForHeight < maxFontSizeForWidth
            ? maxFontSizeForHeight
            : maxFontSizeForWidth;
      } else {
        fontSize = height - 60 - height / 6;
        ledSize = width / ledModules / 8 / 1.2;
      }
    } else {
      fontSize = mobileFontSize;
    }

    pixelsPerSecond = getPixelsPerSecond(fontSize: fontSize);
    // if (kDebugMode) {
    //   debugPrint(
    //       'ScrollMatrixPage => updateSizes, caller: $caller, width: $width, height: $height, fontSize: $fontSize');
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

                double tickerWidth = double.infinity;

                if (mainState.devices.isNotEmpty &&
                    mainState.info.containsKey(ip)) {
                  Map<String, dynamic> i = mainState.info[ip];

                  if (!fontSizeInitialized ||
                      ledModules != i['led_modules'] ||
                      verticalOutput != i['vertical_output']) {
                    ledModules = i['led_modules'];
                    verticalOutput =
                        verticalTickerActive && (i['vertical_output'] ?? false);

                    tickerWidth = ledTickerOnTickerPageActive
                        ? ledModules * ledSize * 8
                        : ledModules * fontSize;

                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        setState(() {
                          ledModules = i['led_modules'];
                          verticalOutput = verticalTickerActive &&
                              (i['vertical_output'] ?? false);
                          if (!fontSizeInitialized) {
                            initMobileFontSize();
                            fontSizeInitialized = true;
                          }
                        });
                      }
                    });
                  }

                  String displaystrNew =
                      verticalOutput ? '' : i['app_displaystr'];

                  if (verticalOutput && verticalTickerActive) {
                    List<String> lines = [];
                    for (String line in List<String>.from(i['vert_strlines'])) {
                      lines.add(
                        mainRepository.replaceIllegalCharsInTickerString(
                          str: line,
                          replaceActiveZoneMarker: !ledTickerOnTickerPageActive,
                        ),
                      );
                    }
                    verticalTextLines = lines;
                  }

                  linePause = i['vertical_scroll_delay'];

                  if (displaystrNew != displaystr) {
                    scrollText =
                        mainRepository.replaceIllegalCharsInTickerString(
                      str: displaystrNew,
                      replaceActiveZoneMarker: !ledTickerOnTickerPageActive,
                    );
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
                    initMobileFontSize();
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
                        child: verticalOutput && verticalTickerActive
                            ? Center(
                                child: SizedBox(
                                  width: tickerWidth,
                                  child: ledTickerOnTickerPageActive
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: ledSize * 0.7),
                                          color: Colors.grey.shade700,
                                          child: Container(
                                            color: Colors.black,
                                            child: UpdatableVerticalLedTicker(
                                              key: ValueKey(
                                                  'UpdatableTickerMatrixPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                                              modules: ledModules,
                                              useProportionalFont: true,
                                              center: true,
                                              ledSize: ledSize,
                                              ledGap: ledGap,
                                              onColor: ledOnColor,
                                              offColor: ledOffColor,
                                              texts: verticalTextLines,
                                              scrollDuration: Duration(
                                                  milliseconds:
                                                      (50 * 8 / sliderValue)
                                                          .floor()),
                                              linePause:
                                                  Duration(seconds: linePause),
                                              cyclePause:
                                                  Duration(seconds: cyclePause),
                                            ),
                                          ),
                                        )
                                      : UpdatableVerticalTicker(
                                          key: ValueKey(
                                              'UpdatableTickerMatrixPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                                          texts: verticalTextLines,
                                          scrollDuration: Duration(
                                              milliseconds:
                                                  (50 * 8 / sliderValue)
                                                      .floor()),
                                          linePause:
                                              Duration(seconds: linePause),
                                          cyclePause:
                                              Duration(seconds: cyclePause),
                                          textStyle: TextStyle(
                                            fontSize: fontSize / 1.2,
                                            color: Colors.black,
                                          ),
                                        ),
                                ),
                              )
                            : ledTickerOnTickerPageActive
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: ledSize * 0.4),
                                          color: Colors.grey.shade700,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  color: Colors.black,
                                                  child: UpdatableLedTicker(
                                                    key: ValueKey(
                                                        'UpdatableTickerMatrixPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                                                    updatableText: scrollText,
                                                    modules: ledModules,
                                                    useProportionalFont: true,
                                                    ledSize: ledSize,
                                                    ledGap: ledGap,
                                                    onColor: ledOnColor,
                                                    offColor: ledOffColor,
                                                    pixelsPerSecond: 100 *
                                                        sliderValue /
                                                        (ledSize * 0.1),
                                                    forceUpdate: false,
                                                    separator:
                                                        Globals.tickerSeparator,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : UpdatableTicker(
                                    key: ValueKey(
                                        'UpdatableTickerMatrixPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                                    updatableText: scrollText,
                                    style: TextStyle(
                                      fontFamily: Globals.tickerFontFamily,
                                      fontSize: fontSize / 1.2,
                                      color: Colors.black,
                                    ),
                                    pixelsPerSecond:
                                        pixelsPerSecond * sliderValue,
                                    forceUpdate: false,
                                    center: true,
                                    separator: Globals.tickerSeparator,
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

    if (Globals.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: Globals.brightness(),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: CupertinoNavigationBarBackButton(),
              onPressed: () => Navigator.pop(context),
            ),
            trailing: SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              child: MobileSpeedSliderAndFontsizeControls(
                key: ValueKey(
                    'MobileSpeedSliderAndFontsizeControls-$ledModules-$orientation-$verticalOutput'),
                translations: translations,
                ip: ip,
                ledModules: ledModules,
                verticalOutput: verticalOutput && verticalTickerActive,
                width: width,
                scrollSpeed: sliderValue,
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
                if (Globals.isDesktopDevice())
                  Positioned(
                    bottom: -10,
                    right: 10,
                    child: SliderHoverOverlay(
                      label: '${translations['speed'] ?? 'speed:'}:',
                      width: width > sliderOverlayMaxWidth
                          ? sliderOverlayMaxWidth
                          : width,
                      min: 0.1,
                      value: sliderValue,
                      updateValue: (double value) {
                        speedChanged(value);
                        setState(() {
                          sliderValue = value;
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

          return Globals.inMacosStyle()
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
                        right: 10,
                        child: SliderHoverOverlay(
                          label: '${translations['speed'] ?? 'speed:'}:',
                          width: width > sliderOverlayMaxWidth
                              ? sliderOverlayMaxWidth
                              : width,
                          min: 0.1,
                          value: sliderValue,
                          updateValue: (double value) {
                            speedChanged(value);
                            setState(() {
                              sliderValue = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  backButtonPressed: () {
                    if (Globals.isDesktopDevice() && !isFullscreen) {
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
                    if (Globals.isDesktopDevice())
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: TitlebarInfoContent(
                          ip: ip,
                          translations: translations,
                        ),
                      ),
                    if (Globals.isMobileDevice())
                      MobileSpeedSliderAndFontsizeControls(
                        key: ValueKey(
                            'MobileSpeedSliderAndFontsizeControls-$ledModules-$orientation-$verticalOutput'),
                        translations: translations,
                        ip: ip,
                        ledModules: ledModules,
                        verticalOutput: verticalOutput && verticalTickerActive,
                        width: width,
                        scrollSpeed: sliderValue,
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
                      if (Globals.isDesktopDevice())
                        Positioned(
                          bottom: -10,
                          right: 10,
                          child: SliderHoverOverlay(
                            label: '${translations['speed'] ?? 'speed:'}:',
                            width: width > sliderOverlayMaxWidth
                                ? sliderOverlayMaxWidth
                                : width,
                            min: 0.1,
                            value: sliderValue,
                            updateValue: (double value) {
                              speedChanged(value);
                              setState(() {
                                sliderValue = value;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  backButtonPressed: () {
                    if (Globals.isDesktopDevice() && !isFullscreen) {
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
