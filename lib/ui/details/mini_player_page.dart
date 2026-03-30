import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/layout/cover_overlay_button.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/zone_corner_label.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart'
    show MainState, MainStateLoaded;
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:window_manager/window_manager.dart';

class MiniPlayerPage extends StatefulWidget {
  final String name;
  final String ip;
  final String? controlId;
  final bool miniPlayerAlwaysOnTop;
  final bool miniPlayerPreventCloseApp;
  final bool miniPlayerShowTextInfoOnTrackChange;
  final int miniPlayerTextInfoDuration;
  final Map<String, dynamic> translations;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const MiniPlayerPage({
    super.key,
    required this.name,
    required this.ip,
    this.controlId,
    required this.miniPlayerAlwaysOnTop,
    required this.miniPlayerPreventCloseApp,
    required this.miniPlayerShowTextInfoOnTrackChange,
    required this.miniPlayerTextInfoDuration,
    required this.translations,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<MiniPlayerPage> createState() => _MiniPlayerPageState();
}

class _MiniPlayerPageState extends State<MiniPlayerPage> with WindowListener {
  String get name => widget.name;
  String get ip => widget.ip;
  Map<String, dynamic> get translations => widget.translations;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final Color textAreaBackgroundColor = Color.fromARGB(200, 0, 0, 0);
  final int textInfoOnTrackChangeDurationInSeconds = 10;

  final double coverPadding = 0.0;
  final double zoneCornerLabelMinCoverSize = 150;
  final bool withAnimatedBackground = false;
  final int buttonStatusSwitchTimeoutInSeconds = 10;

  final bool selectBoxWithoutPadding = true;

  final Duration opacityDuration = const Duration(milliseconds: 200);

  BoxDecoration areaDecorationFilledLightStyle() => BoxDecoration(
        borderRadius: Globals.borderRadius(),
        color:
            Color.fromARGB(withAnimatedBackground ? 255 : 130, 220, 220, 220),
        // color: Color.fromARGB(160, 0, 0, 0),
      );

  BoxDecoration areaDecorationFilledDarkStyle() => BoxDecoration(
        borderRadius: Globals.borderRadius(),
        color: Color.fromARGB(withAnimatedBackground ? 255 : 130, 70, 70, 70),
        // color: Color.fromARGB(160, 0, 0, 0),
      );

  Map<String, dynamic> info = {};
  Map<String, dynamic> webPlayoutsRaw = {};
  Map<String, dynamic> roonPlayoutsRaw = {};
  List<CoverModel> coverList = [];
  CoverModel? coverModel;
  Map<String, dynamic>? selectedZone;

  String title = '';
  String? controlId;
  String macosVersion = '';
  String statusInProgress = '';
  bool idle = false;
  bool shuffle = false;
  bool repeat = false;
  bool isRadio = false;
  bool loaded = false;
  bool isFullscreen = false;
  bool hovered = false;
  bool timedHover = false;
  bool disposed = false;
  Offset actualPosition = Offset(0, 0);
  Size actualSize = Size(600, 600);
  Size defaultSize = Size(600, 600);
  double appBarHeight = 0;
  double? coverWidth;
  double? windowWidth;
  Timer? statusInProgressTimer;

  late MainRepository mainRepository;
  late MainBloc mainBloc;
  late StreamSubscription mainBlocSubscription;
  late SettingsBloc settingsBloc;
  late StreamSubscription settingsBlocSubscription;
  late bool miniPlayerAlwaysOnTop;
  late bool miniPlayerPreventCloseApp;
  late bool miniPlayerShowTextInfoOnTrackChange;
  late int miniPlayerTextInfoDuration;

  @override
  void initState() {
    title =
        '$name : ${translations['miniPlayerPageHeaderText'] ?? 'Mini Player'}';
    miniPlayerAlwaysOnTop = widget.miniPlayerAlwaysOnTop;
    miniPlayerPreventCloseApp = widget.miniPlayerPreventCloseApp;
    miniPlayerShowTextInfoOnTrackChange =
        widget.miniPlayerShowTextInfoOnTrackChange;
    miniPlayerTextInfoDuration = widget.miniPlayerTextInfoDuration;

    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);
    initSubscription();
    windowManager.addListener(this);

    asynInitDesktopDevice();

    settingsBlocSubscription =
        settingsBloc.stream.listen((SettingsState settingsState) {
      if (settingsState is SettingsStateLoaded) {
        if (settingsState.miniPlayerAlwaysOnTop != miniPlayerAlwaysOnTop ||
            settingsState.miniPlayerPreventCloseApp !=
                miniPlayerPreventCloseApp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                miniPlayerAlwaysOnTop = settingsState.miniPlayerAlwaysOnTop;
                miniPlayerPreventCloseApp =
                    settingsState.miniPlayerPreventCloseApp;
                miniPlayerShowTextInfoOnTrackChange =
                    settingsState.miniPlayerShowTextInfoOnTrackChange;
                miniPlayerTextInfoDuration =
                    settingsState.miniPlayerTextInfoDuration;
                windowManager.setAlwaysOnTop(miniPlayerAlwaysOnTop);
                windowManager.setClosable(!miniPlayerPreventCloseApp);
              });
            }
          });
        }
      }
    });

    super.initState();
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
  void onWindowResize() async {
    if (Platform.isLinux && !isFullscreen) {
      EasyDebounce.debounce(
        'miniplayer-resize-debouncer',
        Duration(milliseconds: 200),
        () {
          if (!disposed) {
            setWindowSize();
          }
        },
      );
    }
  }

  @override
  void onWindowResized() async {
    setWindowSize();
  }

  double getAdditionalWindowHeight() {
    if (Globals.inMacosStyle()) {
      return appBarHeight + 8.0;
    }
    if (Globals.inIosStyle()) {
      return appBarHeight + 28.0;
    }
    if (Platform.isWindows) {
      return appBarHeight + 24.0;
    }
    if (Platform.isLinux) {
      return appBarHeight;
    }

    return appBarHeight + 28.0;
  }

  Future<void> setWindowSize() async {
    final double additionalHeight = getAdditionalWindowHeight();
    final Size size = await windowManager.getSize();
    final double realHeight = size.height - additionalHeight;
    final double side = size.width < realHeight ? size.width : realHeight;

    await windowManager.setSize(Size(side, side + additionalHeight));
  }

  Future<void> asynInitDesktopDevice() async {
    final Size size = await windowManager.getSize();
    final Offset position = await windowManager.getPosition();
    final double additionalHeight = getAdditionalWindowHeight();

    windowManager.setFullScreen(false);
    windowManager.setBackgroundColor(Colors.black);
    windowManager.setAlwaysOnTop(widget.miniPlayerAlwaysOnTop);
    windowManager.setClosable(!widget.miniPlayerPreventCloseApp);

    WindowOptions windowOptions = WindowOptions(
      size: defaultSize,
      skipTaskbar: true,
      fullScreen: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        setState(() {
          actualPosition = position;
          actualSize = size;
        });
      }
      if (!Platform.isLinux) {
        windowManager.setAspectRatio(1);
      }
      mainBloc.windowResize(
        size: Size(defaultSize.width, defaultSize.height + additionalHeight),
      );
    });
  }

  initSubscription() {
    mainBlocSubscription = mainBloc.stream.listen((MainState mainState) {
      if (mainState is MainStateLoaded) {
        coverList = mainBloc.getCoversModel(showWebCoverNotRunning: false);
        CoverModel? oldCoverModel = coverModel;
        coverModel = coverList
            .firstWhereOrNull((CoverModel el) => el.controlId == controlId);

        if (statusInProgress == coverModel?.status ||
            (oldCoverModel == null && coverModel != null) ||
            (oldCoverModel != null &&
                coverModel != null &&
                oldCoverModel.track != coverModel!.track)) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              setState(() {
                statusInProgress = '';

                if (miniPlayerShowTextInfoOnTrackChange == true) {
                  hovered = true;
                  timedHover = true;
                }

                if (statusInProgressTimer != null &&
                    statusInProgressTimer!.isActive) {
                  statusInProgressTimer!.cancel();
                }
              });
            }
          });
          if (miniPlayerShowTextInfoOnTrackChange == true) {
            Future.delayed(Duration(seconds: miniPlayerTextInfoDuration), () {
              SchedulerBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  setState(() {
                    timedHover = false;
                    hovered = false;
                  });
                }
              });
            });
          }
        }

        info = mainState.info[ip] ?? {};

        if (macosVersion != mainState.macosVersion) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              setState(() {
                macosVersion = mainState.macosVersion;
              });
            }
          });
        }

        if (info != {} && info['control_id'] != null) {
          String? controlIdUpdated = widget.controlId ?? info['control_id'];

          if (info['web_playouts_raw'] != webPlayoutsRaw ||
              info['roon_playouts_raw'] != roonPlayoutsRaw ||
              controlId == null ||
              controlIdUpdated != controlId) {
            webPlayoutsRaw = info['web_playouts_raw'];
            roonPlayoutsRaw = info['roon_playouts_raw'];

            Map<String, dynamic> data = mainBloc.getZoneDataForControlId(
              info: info,
              controlId: controlIdUpdated,
              isRadio: isRadio,
            );
            if (data['zone'] != null) {
              (data['zone'] as Map<String, dynamic>).remove('position');
            }

            if ((data['zone'] != null && selectedZone != data['zone']) ||
                controlIdUpdated != controlId) {
              SchedulerBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  setState(() {
                    Map<String, dynamic>? zone = data['zone'];

                    controlId = controlIdUpdated;

                    if (zone != null && selectedZone != zone) {
                      selectedZone = zone;
                    }

                    if (controlId != null) {
                      if ((info['shufflemode'] as Map<String, dynamic>)
                          .containsKey(controlId)) {
                        shuffle = info['shufflemode'][controlId] == 'shuffle';
                      }
                      if ((info['repeatmode'] as Map<String, dynamic>)
                          .containsKey(controlId)) {
                        repeat = info['repeatmode'][controlId] == 'repeat';
                      }
                      if ((info['playmode'] as Map<String, dynamic>)
                          .containsKey(controlId)) {
                        idle = info['playmode'][controlId] != 'play';
                      }

                      isRadio = data['isRadio'];
                      if (selectedZone?['zone'] == 'Apple Music') {
                        isRadio =
                            false; // fix for AppleMusic because the delay is too big (every stream with position:0 will be disabling the prev/next button for isRadio == true, but the next infodata update will be loaded 10-15sec later)
                      }
                    }
                  });
                }
              });
            }
          }
        }

        if (!loaded) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              setState(() => loaded = true);
            }
          });
        }
      }
    });
  }

  Widget getCoverArea({
    required BuildContext context,
    required bool portraitMode,
    required Map<String, dynamic>? selectedZone,
  }) =>
      SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: LayoutBuilder(builder: (context, constraints) {
          double maxSize = max(constraints.maxWidth, constraints.maxHeight);

          return Center(
            child: SimpleGestureDetector(
              swipeConfig: SimpleSwipeConfig(
                  horizontalThreshold: 50,
                  swipeDetectionBehavior:
                      SwipeDetectionBehavior.continuousDistinct),
              onHorizontalSwipe: (SwipeDirection direction) {
                if (direction == SwipeDirection.right) {
                  mainBloc.zoneControl(
                      ip: ip, controlId: controlId!, cmd: 'previous');
                }
                if (direction == SwipeDirection.left) {
                  mainBloc.zoneControl(
                      ip: ip, controlId: controlId!, cmd: 'next');
                }
              },
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: Globals.coverSwitchDefaultFadeAnimationDuration,
                    child: mainRepository.coverExistInZone(zone: selectedZone)
                        ? Image.network(
                            selectedZone!['cover'],
                            key: ValueKey(
                                'BigCover-$selectedZone-$idle-${selectedZone['cover']}'),
                            fit: BoxFit.contain,
                            alignment: portraitMode
                                ? Alignment.topCenter
                                : Alignment.centerLeft,
                            colorBlendMode:
                                idle ? ColorDefs.idleZoneColorBlendMode : null,
                            color: idle ? ColorDefs.idleZoneColor : null,
                            width: constraints.maxWidth <= constraints.maxHeight
                                ? double.infinity
                                : null,
                            height:
                                constraints.maxWidth >= constraints.maxHeight
                                    ? double.infinity
                                    : null,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: maxSize,
                                height: maxSize,
                                child: SvgPicture.asset(
                                  Globals.placeholderSvgAssetPath(),
                                  allowDrawingOutsideViewBox: false,
                                  fit: BoxFit.contain,
                                  alignment: portraitMode
                                      ? Alignment.center
                                      : Alignment.centerLeft,
                                  colorFilter: idle
                                      ? ColorDefs.idleZoneColorFilter
                                      : null,
                                ),
                              );
                            },
                          )
                        : SizedBox(
                            width: maxSize,
                            height: maxSize,
                            child: SvgPicture.asset(
                              Globals.placeholderSvgAssetPath(),
                              allowDrawingOutsideViewBox: false,
                              fit: BoxFit.contain,
                              alignment: portraitMode
                                  ? Alignment.center
                                  : Alignment.centerLeft,
                              colorFilter:
                                  idle ? ColorDefs.idleZoneColorFilter : null,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0, //give the values according to your requirement
                    child: Opacity(
                      opacity: ColorDefs.zoneCornerLabelOpacity,
                      child: ZoneCornerLabel(
                        zoneName: '-${selectedZone?['zone'] ?? name}',
                        coverWidth: Globals.zoneCornerFullSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      );

  void setButtonStatusSwitchInProgressTimer() {
    statusInProgressTimer = Timer.periodic(
        Duration(seconds: buttonStatusSwitchTimeoutInSeconds), (Timer timer) {
      statusInProgress = '';
      statusInProgressTimer!.cancel();
    });
  }

  bool get statusUpdateInProgress =>
      statusInProgress.isNotEmpty &&
      coverModel != null &&
      statusInProgress != coverModel!.status;

  Alignment getProgressIndicatorAlignment(String status) {
    if (status == 'previous') {
      return Alignment.centerLeft;
    }
    if (status == 'next') {
      return Alignment.centerRight;
    }
    return Alignment.center;
  }

  void resetWindowSettings() async {
    await windowManager.setAspectRatio(0);
    windowManager.setAlwaysOnTop(false);
    windowManager.setSkipTaskbar(false);
    windowManager.setClosable(true);

    if (!isFullscreen) {
      mainBloc.windowResize(size: actualSize, position: actualPosition);
    }
  }

  Widget body({
    required BuildContext context,
    required MainBloc mainBloc,
  }) =>
      NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {});
          });
          //build(context);
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: SizedBox(
            child: Stack(
              children: [
                !loaded
                    ? SizedBox()
                    : RoonmatrixAnimatedGradient(
                        disabled: !withAnimatedBackground,
                        child: OrientationBuilder(builder:
                            (BuildContext context, Orientation orientation) {
                          windowWidth = MediaQuery.of(context).size.width;

                          return LayoutBuilder(builder: (context, constraints) {
                            final double coverSize = constraints.maxWidth;
                            final double minControlsHeight = 86;
                            double coverHeight = min(
                              coverSize,
                              constraints.maxHeight,
                            );

                            coverWidth = coverHeight;

                            final double controlsHeight = max(
                                  minControlsHeight,
                                  constraints.maxHeight - coverSize,
                                ) -
                                coverPadding;

                            if (kDebugMode) {
                              debugPrint(
                                  'portraitMode cover + controlArea => maxWidth: ${constraints.maxWidth}, coverWidth: $coverWidth, controlsHeight: $controlsHeight');
                            }

                            return Stack(
                              children: [
                                getCoverArea(
                                  context: context,
                                  portraitMode: true,
                                  selectedZone: selectedZone,
                                ),
                                if (coverModel != null)
                                  Positioned(
                                    left: 16.0,
                                    bottom: 16.0,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) => timedHover == true
                                          ? null
                                          : setState(() => hovered = true),
                                      onExit: (_) => timedHover == true
                                          ? null
                                          : setState(() => hovered = false),
                                      child: AnimatedOpacity(
                                        opacity: hovered ? 1.0 : 0.0,
                                        duration: opacityDuration,
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: coverWidth != null
                                                ? coverWidth! - 32.0
                                                : 80,
                                          ),
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                Globals.borderRadius(),
                                            color: textAreaBackgroundColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4.0, vertical: 2.0),
                                            child: SizedBox(
                                              child: CoverTextOverlayExtended(
                                                coverModel: coverModel!,
                                                fontSize:
                                                    (coverWidth ?? 0) / 32,
                                                translations: translations,
                                                coverRowArtist: true,
                                                coverRowAlbum: true,
                                                coverRowTrack: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (coverModel != null)
                                  CoverOverlayButton(
                                    alignment: Alignment.center,
                                    coverWidth: coverWidth ?? 0,
                                    isPlaying: coverModel!.status == 'playing',
                                    additionalVisibility:
                                        (statusUpdateInProgress &&
                                                (statusInProgress ==
                                                        'playing' ||
                                                    statusInProgress ==
                                                        'paused')) ||
                                            coverModel!.status != 'playing',
                                    icon: coverModel!.status == 'playing'
                                        ? Icon(
                                            Icons.pause,
                                            color: statusUpdateInProgress
                                                ? Colors.grey.shade700
                                                : null,
                                          )
                                        : Icon(
                                            Icons.play_arrow,
                                            color: statusUpdateInProgress
                                                ? Colors.grey.shade700
                                                : null,
                                          ),
                                    message: coverModel!.status == 'playing'
                                        ? translations[
                                                'controlButtonPauseText'] ??
                                            'pause'
                                        : translations[
                                                'controlButtonPlayText'] ??
                                            'play',
                                    onPressed: () {
                                      if (!statusUpdateInProgress) {
                                        setButtonStatusSwitchInProgressTimer();
                                        setState(() {
                                          statusInProgress =
                                              coverModel!.status == 'paused'
                                                  ? 'playing'
                                                  : 'paused';
                                        });
                                        mainBloc.zoneControl(
                                          ip: mainBloc.state.activeDeviceIp!,
                                          controlId: coverModel!.controlId,
                                          cmd: 'playmode',
                                          enable:
                                              coverModel!.status != 'playing',
                                        );
                                      }
                                    },
                                  ),
                                if (coverModel != null &&
                                    !coverModel!.isRadio &&
                                    statusUpdateInProgress)
                                  Padding(
                                    padding: statusInProgress == 'previous' ||
                                            statusInProgress == 'next'
                                        ? statusInProgress == 'previous'
                                            ? const EdgeInsets.only(left: 4.0)
                                            : const EdgeInsets.only(right: 4.0)
                                        : EdgeInsets.zero,
                                    child: Align(
                                      alignment: getProgressIndicatorAlignment(
                                        statusInProgress,
                                      ),
                                      child: SizedBox(
                                        width: 16 +
                                            (coverWidth ?? 0) *
                                                Globals
                                                    .overlyPlayoutButtonSizeFactor,
                                        height: 16 +
                                            (coverWidth ?? 0) *
                                                Globals
                                                    .overlyPlayoutButtonSizeFactor,
                                        child: CircularProgressIndicator(
                                          color: ColorDefs.blueIconColor(
                                              context: context),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (coverModel != null &&
                                    !coverModel!.isRadio &&
                                    coverModel!.status == 'playing') ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: CoverOverlayButton(
                                        alignment: Alignment.centerLeft,
                                        coverWidth: coverWidth ?? 0,
                                        isPlaying:
                                            coverModel!.status == 'playing',
                                        additionalVisibility:
                                            statusUpdateInProgress &&
                                                statusInProgress == 'previous',
                                        icon: Icon(
                                          Icons.skip_previous,
                                          color: statusUpdateInProgress
                                              ? Colors.grey.shade700
                                              : null,
                                        ),
                                        message: translations[
                                                'controlButtonPreviousText'] ??
                                            'previous track',
                                        onPressed: () {
                                          if (!statusUpdateInProgress &&
                                              coverModel!.status == 'playing') {
                                            setButtonStatusSwitchInProgressTimer();
                                            setState(() {
                                              statusInProgress = 'previous';
                                            });
                                            mainBloc.zoneControl(
                                              ip: ip,
                                              controlId: coverModel!.controlId,
                                              cmd: 'previous',
                                              enable: true,
                                            );
                                          }
                                        }),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: CoverOverlayButton(
                                      alignment: Alignment.centerRight,
                                      coverWidth: coverWidth ?? 0,
                                      isPlaying:
                                          coverModel!.status == 'playing',
                                      additionalVisibility:
                                          statusUpdateInProgress &&
                                              statusInProgress == 'next',
                                      icon: Icon(
                                        Icons.skip_next,
                                        color: statusUpdateInProgress
                                            ? Colors.grey.shade700
                                            : null,
                                      ),
                                      message: translations[
                                              'controlButtonNextText'] ??
                                          'next track',
                                      onPressed: () {
                                        if (!statusUpdateInProgress &&
                                            coverModel!.status == 'playing') {
                                          setButtonStatusSwitchInProgressTimer();
                                          setState(() {
                                            statusInProgress = 'next';
                                          });
                                          mainBloc.zoneControl(
                                            ip: ip,
                                            controlId: coverModel!.controlId,
                                            cmd: 'next',
                                            enable: true,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            );
                          });
                        }),
                      )
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    ObstructingPreferredSizeWidget? appBarWithActions;
    if (Globals.inMacosStyle() || Globals.inIosStyle()) {
      appBarWithActions = CupertinoNavigationBar(
        brightness: Globals.brightness(),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            resetWindowSettings();
            Navigator.pop(context);
          },
        ),
        middle: Text(
          title,
        ),
      );
      appBarHeight = appBarWithActions.preferredSize.height;
    } else {
      PreferredSizeWidget appBarWithActions = AppBar();
      appBarHeight = appBarWithActions.preferredSize.height;
    }

    if (Globals.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: appBarWithActions,
          child: SafeArea(
            child: body(context: context, mainBloc: mainBloc),
          ),
        ),
      );
    }

    return Globals.inMacosStyle()
        ? PageWithToolbarMacStyle(
            translations: translations,
            title: title,
            standardDesktopSize: standardDesktopSize,
            macosVersion: macosVersion,
            showResizeButtons: false,
            body: body(context: context, mainBloc: mainBloc),
            backButtonPressed: () {
              resetWindowSettings();
            },
            resizeToFullWidth: () {
              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                  minDesktopSize: minDesktopSize);
            },
          )
        : PageWithToolbarFlutterStyle(
            scaffoldKey: scaffoldKey,
            translations: translations,
            title: title,
            sliderDefaultValue: 0.0,
            showSlider: false,
            showResizeButtons: false,
            showExpandableSpeedSlider: false,
            scrollSpeedDevice: 1.0,
            standardDesktopSize: standardDesktopSize,
            body: body(context: context, mainBloc: mainBloc),
            backButtonPressed: () {
              resetWindowSettings();
            },
            resizeToFullWidth: () {
              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                  minDesktopSize: minDesktopSize);
            },
          );
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    mainBlocSubscription.cancel();
    settingsBlocSubscription.cancel();

    windowManager.removeListener(this);

    super.dispose();
  }
}
