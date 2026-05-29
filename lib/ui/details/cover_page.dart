import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:crypto/crypto.dart';
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
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/control_buttons.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/progress_bar_widget.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/swiper_button.dart';
import 'package:roonmatrix/ui/layout/zone_corner_label.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart'
    show MainState, MainStateLoaded;
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:window_manager/window_manager.dart';

class CoverPage extends StatefulWidget {
  final String name;
  final String ip;
  final String? controlId;
  final Map<String, dynamic> translations;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const CoverPage({
    super.key,
    required this.name,
    required this.ip,
    this.controlId,
    required this.translations,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage> with WindowListener {
  String get name => widget.name;
  String get ip => widget.ip;
  Map<String, dynamic> get translations => widget.translations;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey portraitTextAreaKey = GlobalKey();
  final SwiperController swiperController = SwiperController();
  final AutoSizeGroup myGroup = AutoSizeGroup();

  final double coverPadding = 16.0;
  final double zoneCornerLabelMinCoverSize = 150;
  final double fullTextLengthMax = 130;
  final double minTextAreaHeightDesktop = 128.0;
  final double minTextAreaHeightMobile = 100.0;
  final bool withAnimatedBackground = false;
  final double swiperMinHeightPortrait = 224;
  final double swiperMinHeightLandscape = 500;
  final double minControlsHeight = 86;
  final double swiperContentPadding = 40.0;

  final bool threeColsWithoutSpace = false;
  final bool selectBoxWithoutPadding = true;
  final bool showProgressBar = true;
  final bool withSwiper = true;

  final BoxDecoration areaDecorationBorderStyle = BoxDecoration(
    borderRadius: Globals.borderRadius(),
    border: Border.all(color: Colors.black, width: 0, style: BorderStyle.solid),
  );

  Map<String, dynamic> info = {};
  Map<String, String> options = {};
  Map<String, dynamic> webPlayoutsRaw = {};
  Map<String, dynamic> roonPlayoutsRaw = {};
  Map<String, dynamic>? selectedZone;

  String title = '';
  String? selectedZoneId;
  String? controlId;
  String macosVersion = '';
  bool idle = false;
  bool shuffle = false;
  bool repeat = false;
  bool isRadio = false;
  bool loaded = false;
  bool swiperButtonHovered = false;
  double? coverWidth;
  double? windowWidth;

  late MainRepository mainRepository;
  late MainBloc mainBloc;
  late StreamSubscription mainBlocSubscription;

  @override
  void initState() {
    title = '$name : ${translations['coverPageHeaderText'] ?? 'Control'}';
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);
    initSubscription();

    super.initState();
  }

  void initSubscription() {
    mainBlocSubscription = mainBloc.stream.listen((MainState mainState) {
      if (mainState is MainStateLoaded) {
        info = mainState.info[ip] ?? {};

        Map<String, String> optionsUpdated = options;
        if (widget.controlId == null) {
          optionsUpdated = mainBloc.generateZoneSelectionOptionsAndPreselect(
            info: info,
            controlId: controlId,
            setZoneId: ({required String zoneId}) {
              if (selectedZoneId != zoneId) {
                SchedulerBinding.instance.addPostFrameCallback((_) async {
                  if (mounted) {
                    setState(() => selectedZoneId = zoneId);
                  }
                });
              }
            },
          );
        }

        if (macosVersion != mainState.macosVersion ||
            options.keys.join(',') != optionsUpdated.keys.join(',') ||
            options.values.join(',') != optionsUpdated.values.join(',')) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              setState(() {
                macosVersion = mainState.macosVersion;
                options = optionsUpdated;
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
            Map<String, dynamic>? dataZone = data['zone'] != null
                ? Map.from(data['zone'])
                : null;
            if (dataZone != null) {
              dataZone.remove('position');
            }

            if ((dataZone != null && selectedZone != dataZone) ||
                controlIdUpdated != controlId) {
              SchedulerBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  setState(() {
                    Map<String, dynamic>? zone = dataZone;

                    controlId = controlIdUpdated;

                    if (zone != null && selectedZone != zone) {
                      selectedZone = zone;
                      selectedZoneId = zone['server'] == 'roon'
                          ? zone['zone']
                          : '${zone['server']}-${zone['zone']}';
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

  double getTextAreaFontSize({
    required bool showSwiper,
    required bool threeCols,
    required double width,
    required double height,
  }) {
    double heightNetto = height;

    if (threeCols == true) {
      heightNetto -= 140;
    }
    double dimension = width * heightNetto;
    double fontSize = Globals.isDesktopDevice() ? 20 : 16;

    if (dimension < 135000) {
      fontSize = 16;
    }

    if (dimension < 80000) {
      fontSize = 14;
    }

    if (dimension < 50000 || dimension == double.infinity) {
      fontSize = 12;
    }

    // print(
    //   'dimension: ${width * heightNetto}, width: $width, height: $heightNetto, fontSize: $fontSize',
    // );

    return fontSize;
  }

  Widget getTextArea({
    required GlobalKey key,
    required bool portraitMode,
    required bool showSwiper,
    required bool threeCols,
    required double width,
    required double height,
    required double fontSize,
  }) {
    if (selectedZone == null ||
        selectedZone!.isEmpty ||
        selectedZone!['cover'] == null) {
      // zone is inactive
      return Row(
        key: key,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 2.0,
              ),
              child: Column(
                children: [
                  Wrap(
                    children: [
                      Text(
                        '${translations['coverZoneHeader'] ?? 'Zone'}: ${(selectedZone?['server'] == 'roon' ? selectedZone!['zone'] : selectedZone?['server'] ?? '').toString().toFirstUpper}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: Globals.brightness() == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Text(
                        ' (${translations['inactive'] ?? 'inactive zone'})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: Globals.brightness() == Brightness.dark
                              ? Colors.red.shade400
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (selectedZone != null &&
        selectedZone!.isNotEmpty &&
        selectedZone!['artist'] != null) {
      String zoneName = selectedZone!['zone'] != null
          ? (selectedZone!['server'] == 'roon'
                    ? selectedZone!['zone']
                    : selectedZone!['server'])
                .toString()
                .toFirstUpper
          : '';

      String hash = md5
          .convert(
            utf8.encode(
              '$zoneName-${selectedZone!['artist']}-${selectedZone!['album']}-${selectedZone!['track']}-${selectedZone!['status']}',
            ),
          )
          .toString();

      CoverModel coverModel = CoverModel(
        hash: hash,
        controlId: zoneName,
        zoneName: zoneName,
        isRadio: false,
        coverUrl: '',
        artist: selectedZone!['artist'],
        album: selectedZone!['album'],
        track: selectedZone!['track'],
        status: selectedZone!['status'],
      );

      final int fullTextLength =
          coverModel.zoneName.length +
          coverModel.artist.length +
          coverModel.album.length +
          coverModel.album.length +
          coverModel.track.length;
      bool longText =
          fullTextLength > fullTextLengthMax &&
          (MediaQuery.of(context).size.height < (portraitMode ? 700 : 568) ||
              (!portraitMode && MediaQuery.of(context).size.width < 1024));

      if (longText && fontSize >= 14) {
        fontSize = fontSize > 14 ? 14 : 11;
      }
      // if (kDebugMode) {
      //   debugPrint(
      //       'fullTextLength: $fullTextLength, width: ${MediaQuery.of(context).size.width}, height: ${MediaQuery.of(context).size.height}, longText: $longText, fontSize: $fontSize, fontSizeFinal: $fontSizeFinal');
      // }

      Widget inner = Container(
        width: width,
        height: height - 5,
        constraints: threeCols
            ? null
            : BoxConstraints(
                minHeight: Globals.isMobileDevice()
                    ? minTextAreaHeightMobile
                    : minTextAreaHeightDesktop,
                //maxHeight: height - 32,
              ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              print(
                'x43859f7 is: $width x $height, max: ${constraints.maxWidth} x ${constraints.maxHeight}',
              );

              return Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: Globals.borderRadius(),
                  color: Globals.brightness() == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                  boxShadow: [
                    BoxShadow(
                      color: Globals.brightness() == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 5.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: CoverTextOverlayExtended(
                    coverModel: coverModel,
                    fontSize: 18,
                    group: myGroup,
                    color: Globals.brightness() == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    translations: translations,
                    coverRowArtist: true,
                    coverRowAlbum: true,
                    coverRowTrack: true,
                    longText: longText,
                  ),
                ),
              );
            },
          ),
        ),
      );

      return Container(
        padding: showSwiper == true
            ? EdgeInsets.symmetric(horizontal: swiperContentPadding)
            : null,
        child: ClipRRect(
          key: key,
          child: AnimatedSwitcher(
            duration: Globals.coverSwitchDefaultFadeAnimationDuration * 0.6,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 1),
                  end: Offset(0, 0),
                ).animate(animation),
                child: child,
              );
            },
            child: threeCols
                ? Column(
                    key: ValueKey('Text-$idle-$hash'),
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [inner],
                  )
                : IntrinsicHeight(
                    key: ValueKey('Text-$idle-$hash'),
                    child: inner,
                  ),
          ),
        ),
      );
    }

    return SizedBox(key: key);
  }

  Map<String, dynamic> updateZoneSelection({required String? newValue}) {
    if (newValue != null) {
      String? selectedControlId;
      if (options[newValue] != null &&
          (options[newValue] == 'webserver' ||
              options[newValue] == 'spotifyconnect')) {
        selectedControlId = newValue;
      } else {
        selectedControlId = options[newValue];
      }

      if (selectedControlId != null) {
        mainBloc.zoneControl(
          ip: ip,
          controlId: selectedControlId,
          cmd: 'switch',
        );

        Map<String, dynamic> data = mainBloc.getZoneDataForControlId(
          info: info,
          controlId: selectedControlId,
          isRadio: isRadio,
        );
        Map<String, dynamic>? zone = data['zone'];
        isRadio = data['isRadio'];
        if (zone?['zone'] == 'Apple Music') {
          isRadio =
              false; // fix for AppleMusic because the delay is too big (every stream with position:0 will be disabling the prev/next button for isRadio == true, but the next infodata update will be loaded 10-15sec later)
        }
        if (zone != null) {
          // print(
          //  'getSelectBoxArea selected now => selectedZoneId: $newValue, controlId: $selectedControlId, selectedZone: $zone');
          //   object examples:
          //   getSelectBoxArea selected now => selectedZoneId: MacStudio-Apple Music, controlId: MacStudio-Apple Music, selectedZone: {zone: Apple Music, status: playing, artist: Oliver Sim, album: Telephone Games - Single, track: Telephone Games, shuffle: false, repeat: off, position: 3, total: 206, sourcetype: stream, id: 183112, cover: http://192.168.0.107/roonmatrix/covers/coverAppleMusic_6acc8951d35c8d321dc4cc9b9f4cfa31.jpg, server: MacStudio, is_radio: false}
          //   getSelectBoxArea selected now => selectedZoneId: MINI-I Pro, controlId: 16012dba88c8251185467b25cdabf32f684a, selectedZone: {status: paused, artist: Bicep, album: CHROMA 000, track: CHROMA 012 TANGZ II, shuffle: false, repeat: false, position: 134, total: 282, cover: http://192.168.0.200:9330/api/image/1ca35a9f3f61164115b3eacdc3b683ff?scale=fit&width=500&height=500, zone: MINI-I Pro, server: roon, is_radio: false}

          return {
            "selectedZoneId": newValue,
            "controlId": selectedControlId,
            "selectedZone": zone,
          };
        }
      }
    } else {
      return {"selectedZoneId": null};
    }

    return {};
  }

  Widget getSelectBoxArea({
    required bool portraitMode,
    required bool threeCols,
    withLabel = true,
    required Map<String, String> options,
    double? width,
  }) {
    if (selectBoxWithoutPadding == true &&
        (Globals.inIosStyle() || !threeCols)) {
      return Row(
        mainAxisAlignment: portraitMode
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          SizedBox(
            width: width != null ? width + (portraitMode ? 0 : 4) : null,
            child: Padding(
              padding: EdgeInsets.only(
                top: coverPadding,
                bottom: portraitMode ? coverPadding : 0,
              ),
              child: Tooltip(
                message: translations['selectZoneTooltip'] ?? 'Select zone',
                waitDuration: Globals.tooltipWaitDuration,
                child: SelectBox(
                  key: ValueKey('ZoneSelectBox-$selectedZoneId'),
                  translations: translations,
                  aligned: 'inline',
                  placeholder:
                      '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
                  inRow: true,
                  noVerticalSpace: true,
                  readOnly: false,
                  maxWidth: width != null
                      ? width -
                            (portraitMode ? 20 : 16) -
                            (Globals.inMacosStyle() ? 15 : 0)
                      : null,
                  elementExpanded: true,
                  selected: options[selectedZoneId] != null
                      ? selectedZoneId
                      : null,
                  options: options,
                  onChanged: (String? newValue) {
                    Map<String, dynamic> updateData = updateZoneSelection(
                      newValue: newValue,
                    );
                    selectedZoneId =
                        updateData['selectedZoneId'] ?? selectedZoneId;
                    controlId = updateData['controlId'] ?? controlId;
                    selectedZone = updateData['selectedZone'] ?? selectedZone;
                    if (mounted && updateData.keys.isNotEmpty) {
                      setState(() {
                        selectedZoneId =
                            updateData['selectedZoneId'] ?? selectedZoneId;
                        controlId = updateData['controlId'] ?? controlId;
                        selectedZone =
                            updateData['selectedZone'] ?? selectedZone;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.only(
        top: coverPadding,
        right: portraitMode ? 0 : coverPadding,
        bottom: portraitMode ? coverPadding : 0,
      ),
      decoration: Globals.brightness() == Brightness.dark
          ? ColorDefs.areaDecorationFilledDarkStyle(
              withAnimatedBackground: withAnimatedBackground,
            )
          : ColorDefs.areaDecorationFilledLightStyle(
              withAnimatedBackground: withAnimatedBackground,
            ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: translations['selectZoneTooltip'] ?? 'Select zone',
              waitDuration: Duration(seconds: 2),
              child: SelectBox(
                key: ValueKey('ZoneSelectBox-$selectedZoneId'),
                translations: translations,
                aligned: 'horizontal',
                placeholder:
                    '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
                inRow: true,
                noVerticalSpace: false,
                elementExpanded:
                    width != null && width <= 300, // maybe throws error
                readOnly: false,
                maxWidth: width != null && width <= 300 ? width - 70 : null,
                selected: options[selectedZoneId] != null
                    ? selectedZoneId
                    : null,
                options: options,
                onChanged: (String? newValue) {
                  Map<String, dynamic> updateData = updateZoneSelection(
                    newValue: newValue,
                  );
                  selectedZoneId =
                      updateData['selectedZoneId'] ?? selectedZoneId;
                  controlId = updateData['controlId'] ?? controlId;
                  selectedZone = updateData['selectedZone'] ?? selectedZone;
                  if (mounted && updateData.keys.isNotEmpty) {
                    setState(() {
                      selectedZoneId =
                          updateData['selectedZoneId'] ?? selectedZoneId;
                      controlId = updateData['controlId'] ?? controlId;
                      selectedZone = updateData['selectedZone'] ?? selectedZone;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getCoverArea({
    required BuildContext context,
    required bool portraitMode,
    required bool noRightPadding,
    required Map<String, dynamic>? selectedZone,
  }) => Container(
    margin: EdgeInsets.only(bottom: portraitMode ? 16.0 : 0.0),
    width: double.infinity,
    height: double.infinity,
    padding: portraitMode ? EdgeInsets.all(0) : EdgeInsets.all(coverPadding),
    child: LayoutBuilder(
      builder: (context, constraints) {
        double maxSize = max(constraints.maxWidth, constraints.maxHeight);
        double minSize = min(constraints.maxWidth, constraints.maxHeight);

        if (minSize < zoneCornerLabelMinCoverSize) {
          return ZoneCornerLabel(
            zoneName: '-${selectedZone?['zone'] ?? name}',
            coverWidth: Globals.zoneCornerFullSize,
            asRoundVariant: true,
          );
        }

        return Center(
          child: ClipRRect(
            borderRadius: Globals.borderRadius(),
            child: SimpleGestureDetector(
              onHorizontalSwipe: (SwipeDirection direction) {
                if (Globals.isMobileDevice() &&
                    direction == SwipeDirection.right) {
                  mainBloc.zoneControl(
                    ip: ip,
                    controlId: controlId!,
                    cmd: 'previous',
                  );
                }
                if (Globals.isMobileDevice() &&
                    direction == SwipeDirection.left) {
                  mainBloc.zoneControl(
                    ip: ip,
                    controlId: controlId!,
                    cmd: 'next',
                  );
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
                              'BigCover-$selectedZone-$idle-${selectedZone['cover']}',
                            ),
                            fit: BoxFit.contain,
                            alignment: portraitMode
                                ? Alignment.topCenter
                                : Alignment.centerLeft,
                            colorBlendMode: idle
                                ? ColorDefs.idleZoneColorBlendMode
                                : null,
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
                              colorFilter: idle
                                  ? ColorDefs.idleZoneColorFilter
                                  : null,
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
          ),
        );
      },
    ),
  );

  Widget getControlArea({
    required bool portraitMode,
    required bool showSwiper,
    required Orientation orientation,
    required bool threeCols,
    required bool idle,
    required bool shuffle,
    required bool repeat,
    required bool isRadio,
    required String? selectedZoneId,
  }) => Container(
    width: portraitMode ? null : double.infinity,
    //height: portraitMode || threeCols ? null : double.infinity,
    margin: portraitMode
        ? EdgeInsets.only(
            right: portraitMode ? 0 : coverPadding,
            bottom: showSwiper == true ? 0 : coverPadding,
          )
        : EdgeInsets.only(
            right: coverPadding,
            top: coverPadding,
            bottom: coverPadding,
          ),
    padding: showSwiper == true
        ? EdgeInsets.symmetric(
            horizontal: swiperContentPadding,
            vertical: showSwiper == true && portraitMode
                ? 0
                : swiperContentPadding,
          )
        : null,
    decoration: Globals.brightness() == Brightness.dark
        ? ColorDefs.areaDecorationFilledDarkStyle(
            withAnimatedBackground: withAnimatedBackground,
          )
        : ColorDefs.areaDecorationFilledLightStyle(
            withAnimatedBackground: withAnimatedBackground,
          ),
    child: Center(
      child: ControlButtons(
        key: ValueKey('ControButtonsDesktop-$idle-$shuffle-$repeat-$isRadio'),
        orientation: orientation,
        translations: translations,
        portraitMode: portraitMode,
        padding: coverPadding,
        ip: ip,
        controlId: controlId ?? widget.controlId ?? '',
        idle: idle,
        shuffle: shuffle,
        repeat: repeat,
        isRadio: isRadio,
        readOnly: selectedZoneId == null || selectedZoneId.isEmpty,
      ),
    ),
  );

  Widget body({
    required BuildContext context,
    required MainBloc mainBloc,
  }) => NotificationListener<SizeChangedLayoutNotification>(
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
                    child: OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                        final bool threeCols =
                            MediaQuery.of(context).size.width /
                                MediaQuery.of(context).size.height >
                            2.5;
                        bool portraitMode =
                            (Globals.isMobileDevice() &&
                                orientation == Orientation.portrait) ||
                            (Globals.isDesktopDevice() &&
                                MediaQuery.of(context).size.height >
                                    MediaQuery.of(context).size.width);

                        windowWidth = MediaQuery.of(context).size.width;

                        bool showSwiper =
                            withSwiper == true &&
                            (Globals.isMobileDevice() ||
                                (MediaQuery.of(context).size.height /
                                        windowWidth!) <
                                    2.5);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            double maxContentHeight = constraints.maxHeight;

                            return portraitMode
                                ? Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: coverPadding,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        widget.controlId == null
                                            ? LayoutBuilder(
                                                builder:
                                                    (context, constraints) {
                                                      return getSelectBoxArea(
                                                        portraitMode:
                                                            portraitMode,
                                                        threeCols: threeCols,
                                                        withLabel:
                                                            coverWidth !=
                                                                null &&
                                                            coverWidth! > 300,
                                                        options: options,
                                                        width: min(
                                                          constraints.maxWidth,
                                                          coverWidth ?? 200,
                                                        ),
                                                      );
                                                    },
                                              )
                                            : SizedBox(height: 16.0),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final double coverSize =
                                                  constraints.maxWidth;

                                              double coverHeight = min(
                                                coverSize,
                                                constraints.maxHeight -
                                                    (showSwiper
                                                        ? swiperMinHeightPortrait
                                                        : minControlsHeight),
                                              );
                                              if (coverHeight <
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.height /
                                                      2) {
                                                coverHeight =
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height /
                                                    2;
                                              }

                                              coverWidth = coverHeight;

                                              final double controlsHeight =
                                                  max(
                                                    showSwiper
                                                        ? swiperMinHeightPortrait
                                                        : minControlsHeight,
                                                    constraints.maxHeight -
                                                        coverSize,
                                                  ) -
                                                  coverPadding;

                                              if (kDebugMode) {
                                                debugPrint(
                                                  'portraitMode cover + controlArea => maxWidth: ${constraints.maxWidth}, coverWidth: $coverWidth, controlsHeight: $controlsHeight',
                                                );
                                              }

                                              return Column(
                                                children: [
                                                  Expanded(
                                                    child: getCoverArea(
                                                      context: context,
                                                      portraitMode:
                                                          portraitMode,
                                                      noRightPadding: true,
                                                      selectedZone:
                                                          selectedZone,
                                                    ),
                                                  ),
                                                  if (showSwiper == true)
                                                    Container(
                                                      constraints:
                                                          coverWidth != null
                                                          ? BoxConstraints(
                                                              minWidth:
                                                                  coverWidth!,
                                                              maxWidth:
                                                                  coverWidth!,
                                                            )
                                                          : null,
                                                      width: coverWidth!,
                                                      height: controlsHeight,
                                                      child: Stack(
                                                        children: [
                                                          Swiper.children(
                                                            autoplay: false,
                                                            outer: true,
                                                            scale: 0.7,
                                                            controller:
                                                                swiperController,
                                                            pagination: const SwiperPagination(
                                                              margin:
                                                                  EdgeInsets.fromLTRB(
                                                                    0.0,
                                                                    4.0,
                                                                    0.0,
                                                                    4.0,
                                                                  ),
                                                              builder:
                                                                  DotSwiperPaginationBuilder(
                                                                    color: Colors
                                                                        .grey,
                                                                    activeColor:
                                                                        Colors
                                                                            .blue,
                                                                    size: 10.0,
                                                                    activeSize:
                                                                        10.0,
                                                                  ),
                                                            ),
                                                            children: <Widget>[
                                                              Column(
                                                                children: [
                                                                  Expanded(
                                                                    child: Container(
                                                                      constraints:
                                                                          coverWidth !=
                                                                              null
                                                                          ? BoxConstraints(
                                                                              minWidth: coverWidth!,
                                                                              maxWidth: coverWidth!,
                                                                            )
                                                                          : null,
                                                                      width:
                                                                          coverWidth !=
                                                                              null
                                                                          ? (coverWidth! -
                                                                                coverPadding)
                                                                          : 200,
                                                                      decoration:
                                                                          Globals.brightness() ==
                                                                              Brightness.dark
                                                                          ? ColorDefs.areaDecorationFilledDarkStyle(
                                                                              withAnimatedBackground: withAnimatedBackground,
                                                                            )
                                                                          : ColorDefs.areaDecorationFilledLightStyle(
                                                                              withAnimatedBackground: withAnimatedBackground,
                                                                            ),
                                                                      child: LayoutBuilder(
                                                                        builder:
                                                                            (
                                                                              context,
                                                                              constraints,
                                                                            ) {
                                                                              double
                                                                              width = constraints.maxWidth;
                                                                              double
                                                                              height = constraints.maxHeight;

                                                                              WidgetsBinding.instance.addPostFrameCallback(
                                                                                (
                                                                                  _,
                                                                                ) {
                                                                                  final keyContext = portraitTextAreaKey.currentContext;
                                                                                  if (keyContext !=
                                                                                      null) {
                                                                                    final box =
                                                                                        keyContext.findRenderObject()
                                                                                            as RenderBox;
                                                                                    width = box.size.width;
                                                                                    height = box.size.height;

                                                                                    if (kDebugMode) {
                                                                                      debugPrint(
                                                                                        'portraitMode textArea => size: $width x $height, maxWidth: ${constraints.maxWidth}',
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                              );

                                                                              return Container(
                                                                                child: getTextArea(
                                                                                  key: portraitTextAreaKey,
                                                                                  portraitMode: portraitMode,
                                                                                  showSwiper: showSwiper,
                                                                                  threeCols: threeCols,
                                                                                  width: width,
                                                                                  height: height,
                                                                                  fontSize: getTextAreaFontSize(
                                                                                    showSwiper: showSwiper,
                                                                                    threeCols: threeCols,
                                                                                    width: width,
                                                                                    height: height,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  if (showProgressBar ==
                                                                      true)
                                                                    SizedBox(
                                                                      width:
                                                                          coverWidth ??
                                                                          200,
                                                                      child: ProgressBarWidget(
                                                                        ip: ip,
                                                                        controlId:
                                                                            controlId,
                                                                        coverPadding:
                                                                            coverPadding,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    coverWidth!,
                                                                height:
                                                                    controlsHeight,
                                                                child: getControlArea(
                                                                  portraitMode:
                                                                      portraitMode,
                                                                  showSwiper:
                                                                      showSwiper,
                                                                  orientation:
                                                                      orientation,
                                                                  threeCols:
                                                                      threeCols,
                                                                  idle: idle,
                                                                  shuffle:
                                                                      shuffle,
                                                                  repeat:
                                                                      repeat,
                                                                  isRadio:
                                                                      isRadio,
                                                                  selectedZoneId:
                                                                      selectedZoneId,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          if (Globals.isDesktopDevice())
                                                            SwiperButton(
                                                              swiperController:
                                                                  swiperController,
                                                              isNext: false,
                                                              top:
                                                                  (controlsHeight /
                                                                      2) -
                                                                  36,
                                                            ),
                                                          if (Globals.isDesktopDevice())
                                                            SwiperButton(
                                                              swiperController:
                                                                  swiperController,
                                                              isNext: true,
                                                              top:
                                                                  (controlsHeight /
                                                                      2) -
                                                                  36,
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                  if (!showSwiper)
                                                    SizedBox(
                                                      width: coverWidth!,
                                                      height: controlsHeight,
                                                      child: getControlArea(
                                                        portraitMode:
                                                            portraitMode,
                                                        showSwiper: false,
                                                        orientation:
                                                            orientation,
                                                        threeCols: threeCols,
                                                        idle: idle,
                                                        shuffle: shuffle,
                                                        repeat: repeat,
                                                        isRadio: isRadio,
                                                        selectedZoneId:
                                                            selectedZoneId,
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),

                                        if (!showSwiper)
                                          Container(
                                            constraints: coverWidth != null
                                                ? BoxConstraints(
                                                    minWidth: coverWidth!,
                                                    maxWidth: coverWidth!,
                                                  )
                                                : null,
                                            width: coverWidth != null
                                                ? (coverWidth! - coverPadding)
                                                : 200,
                                            decoration:
                                                Globals.brightness() ==
                                                    Brightness.dark
                                                ? ColorDefs.areaDecorationFilledDarkStyle(
                                                    withAnimatedBackground:
                                                        withAnimatedBackground,
                                                  )
                                                : ColorDefs.areaDecorationFilledLightStyle(
                                                    withAnimatedBackground:
                                                        withAnimatedBackground,
                                                  ),
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                double width =
                                                    constraints.maxWidth;
                                                double height =
                                                    constraints.maxHeight;

                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      final keyContext =
                                                          portraitTextAreaKey
                                                              .currentContext;
                                                      if (keyContext != null) {
                                                        final box =
                                                            keyContext
                                                                    .findRenderObject()
                                                                as RenderBox;
                                                        width = box.size.width;
                                                        height =
                                                            box.size.height;

                                                        if (kDebugMode) {
                                                          debugPrint(
                                                            'portraitMode textArea => size: $width x $height, maxWidth: ${constraints.maxWidth}',
                                                          );
                                                        }
                                                      }
                                                    });

                                                return getTextArea(
                                                  key: portraitTextAreaKey,
                                                  portraitMode: portraitMode,
                                                  showSwiper: showSwiper,
                                                  threeCols: threeCols,
                                                  width: width,
                                                  height: height,
                                                  fontSize: getTextAreaFontSize(
                                                    showSwiper: false,
                                                    threeCols: threeCols,
                                                    width: width,
                                                    height: height,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        if (showProgressBar == true &&
                                            !showSwiper)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              bottom: coverPadding,
                                            ),
                                            child: SizedBox(
                                              width: coverWidth ?? 200,
                                              child: ProgressBarWidget(
                                                ip: ip,
                                                controlId: controlId,
                                                coverPadding: coverPadding,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    children: [
                                      windowWidth == null ||
                                              windowWidth! >
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.height +
                                                      250 // limit width to cover area height (no flex)
                                          ? Container(
                                              constraints: BoxConstraints(
                                                maxWidth: maxContentHeight,
                                                maxHeight: maxContentHeight,
                                              ),
                                              child: getCoverArea(
                                                context: context,
                                                portraitMode: portraitMode,
                                                noRightPadding: false,
                                                selectedZone: selectedZone,
                                              ),
                                            )
                                          : Flexible(
                                              flex: 1,
                                              child: getCoverArea(
                                                context: context,
                                                portraitMode: portraitMode,
                                                noRightPadding: false,
                                                selectedZone: selectedZone,
                                              ),
                                            ),
                                      if (threeCols &&
                                          !threeColsWithoutSpace &&
                                          MediaQuery.of(context).size.width /
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height >
                                              3.5) // add flexible fillup space between cover and control/text
                                        Flexible(child: Container()),
                                      threeCols
                                          ? threeColsWithoutSpace == true
                                                ? Flexible(
                                                    flex: 1,
                                                    child: LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        if (kDebugMode) {
                                                          debugPrint(
                                                            'threeColumnMode controlArea (flex) => size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                          );
                                                        }
                                                        return getControlArea(
                                                          portraitMode:
                                                              portraitMode,
                                                          showSwiper: false,
                                                          orientation:
                                                              orientation,
                                                          threeCols: threeCols,
                                                          idle: idle,
                                                          shuffle: shuffle,
                                                          repeat: repeat,
                                                          isRadio: isRadio,
                                                          selectedZoneId:
                                                              selectedZoneId,
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      if (kDebugMode) {
                                                        debugPrint(
                                                          'threeColumnMode controlArea (limit width) => controlarea size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                        );
                                                      }
                                                      return SizedBox(
                                                        width: constraints
                                                            .maxHeight,
                                                        child: getControlArea(
                                                          portraitMode:
                                                              portraitMode,
                                                          showSwiper: false,
                                                          orientation:
                                                              orientation,
                                                          threeCols: threeCols,
                                                          idle: idle,
                                                          shuffle: shuffle,
                                                          repeat: repeat,
                                                          isRadio: isRadio,
                                                          selectedZoneId:
                                                              selectedZoneId,
                                                        ),
                                                      );
                                                    },
                                                  )
                                          : Flexible(
                                              flex: 1,
                                              child: Column(
                                                children: [
                                                  if (MediaQuery.of(
                                                        context,
                                                      ).size.width >
                                                      565)
                                                    widget.controlId == null
                                                        ? LayoutBuilder(
                                                            builder:
                                                                (
                                                                  context,
                                                                  constraints,
                                                                ) {
                                                                  if (kDebugMode) {
                                                                    debugPrint(
                                                                      'twoColumnMode selectboxArea => size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                                    );
                                                                  }
                                                                  return getSelectBoxArea(
                                                                    portraitMode:
                                                                        portraitMode,
                                                                    threeCols:
                                                                        threeCols,
                                                                    options:
                                                                        options,
                                                                    withLabel:
                                                                        constraints
                                                                            .maxWidth >=
                                                                        380,
                                                                    width:
                                                                        constraints
                                                                            .maxWidth -
                                                                        20,
                                                                  );
                                                                },
                                                          )
                                                        : SizedBox(),

                                                  if (showSwiper == true &&
                                                      MediaQuery.of(
                                                            context,
                                                          ).size.height <
                                                          swiperMinHeightLandscape)
                                                    Expanded(
                                                      child: LayoutBuilder(
                                                        builder: (context, constraints) {
                                                          if (kDebugMode) {
                                                            debugPrint(
                                                              'twoColumnMode textAndProgressBarArea => size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                            );
                                                          }

                                                          return Stack(
                                                            children: [
                                                              Swiper.children(
                                                                autoplay: false,
                                                                outer: false,
                                                                scale: 0.7,
                                                                controller:
                                                                    swiperController,
                                                                pagination: const SwiperPagination(
                                                                  margin:
                                                                      EdgeInsets.fromLTRB(
                                                                        0.0,
                                                                        16.0,
                                                                        16.0,
                                                                        24.0,
                                                                      ),
                                                                  builder: DotSwiperPaginationBuilder(
                                                                    color: Colors
                                                                        .grey,
                                                                    activeColor:
                                                                        Colors
                                                                            .blue,
                                                                    size: 10.0,
                                                                    activeSize:
                                                                        10.0,
                                                                  ),
                                                                ),
                                                                children: <Widget>[
                                                                  Column(
                                                                    children: [
                                                                      Expanded(
                                                                        child: Container(
                                                                          margin: EdgeInsets.only(
                                                                            top:
                                                                                coverPadding,
                                                                            bottom:
                                                                                threeCols
                                                                                ? coverPadding
                                                                                : 0,
                                                                            right:
                                                                                coverPadding,
                                                                          ),
                                                                          decoration:
                                                                              Globals.brightness() ==
                                                                                  Brightness.dark
                                                                              ? ColorDefs.areaDecorationFilledDarkStyle(
                                                                                  withAnimatedBackground: withAnimatedBackground,
                                                                                )
                                                                              : ColorDefs.areaDecorationFilledLightStyle(
                                                                                  withAnimatedBackground: withAnimatedBackground,
                                                                                ),
                                                                          child: LayoutBuilder(
                                                                            builder:
                                                                                (
                                                                                  context,
                                                                                  constraints,
                                                                                ) {
                                                                                  double width = constraints.maxWidth;
                                                                                  double height = constraints.maxHeight;

                                                                                  WidgetsBinding.instance.addPostFrameCallback(
                                                                                    (
                                                                                      _,
                                                                                    ) {
                                                                                      final keyContext = portraitTextAreaKey.currentContext;
                                                                                      if (keyContext !=
                                                                                          null) {
                                                                                        final box =
                                                                                            keyContext.findRenderObject()
                                                                                                as RenderBox;
                                                                                        width = box.size.width;
                                                                                        height = box.size.height;

                                                                                        if (kDebugMode) {
                                                                                          debugPrint(
                                                                                            'twoColumnMode textarea => size: $width x $height',
                                                                                          );
                                                                                        }
                                                                                      }
                                                                                    },
                                                                                  );

                                                                                  return getTextArea(
                                                                                    key: portraitTextAreaKey,
                                                                                    portraitMode: portraitMode,
                                                                                    showSwiper: showSwiper,
                                                                                    threeCols: threeCols,
                                                                                    width: width,
                                                                                    height: height,
                                                                                    fontSize: getTextAreaFontSize(
                                                                                      showSwiper: false,
                                                                                      threeCols: threeCols,
                                                                                      width: width,
                                                                                      height: height,
                                                                                    ),
                                                                                  );
                                                                                },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (showProgressBar ==
                                                                          true)
                                                                        LayoutBuilder(
                                                                          builder:
                                                                              (
                                                                                context,
                                                                                constraints,
                                                                              ) {
                                                                                double
                                                                                width = constraints.maxWidth;
                                                                                return SizedBox(
                                                                                  width: width,
                                                                                  child: Padding(
                                                                                    padding: EdgeInsets.only(
                                                                                      right: coverPadding,
                                                                                      bottom: coverPadding,
                                                                                    ),
                                                                                    child: ProgressBarWidget(
                                                                                      ip: ip,
                                                                                      controlId: controlId,
                                                                                      coverPadding: coverPadding,
                                                                                      verticalPadding: 10.0,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                        ),
                                                                    ],
                                                                  ),

                                                                  LayoutBuilder(
                                                                    builder:
                                                                        (
                                                                          context,
                                                                          constraints,
                                                                        ) {
                                                                          if (kDebugMode) {
                                                                            debugPrint(
                                                                              'twoColumnMode controlArea => size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                                            );
                                                                          }
                                                                          return getControlArea(
                                                                            portraitMode:
                                                                                portraitMode,
                                                                            showSwiper:
                                                                                showSwiper,
                                                                            orientation:
                                                                                orientation,
                                                                            threeCols:
                                                                                threeCols,
                                                                            idle:
                                                                                idle,
                                                                            shuffle:
                                                                                shuffle,
                                                                            repeat:
                                                                                repeat,
                                                                            isRadio:
                                                                                isRadio,
                                                                            selectedZoneId:
                                                                                selectedZoneId,
                                                                          );
                                                                        },
                                                                  ),
                                                                ],
                                                              ),
                                                              if (Globals.isDesktopDevice())
                                                                SwiperButton(
                                                                  swiperController:
                                                                      swiperController,
                                                                  isNext: false,
                                                                  top:
                                                                      (constraints
                                                                              .maxHeight /
                                                                          2) -
                                                                      24,
                                                                ),
                                                              if (Globals.isDesktopDevice())
                                                                SwiperButton(
                                                                  swiperController:
                                                                      swiperController,
                                                                  isNext: true,
                                                                  top:
                                                                      (constraints
                                                                              .maxHeight /
                                                                          2) -
                                                                      24,
                                                                  right:
                                                                      coverPadding,
                                                                ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ),

                                                  if (!showSwiper ||
                                                      MediaQuery.of(
                                                            context,
                                                          ).size.height >=
                                                          swiperMinHeightLandscape) ...[
                                                    Flexible(
                                                      child: LayoutBuilder(
                                                        builder: (context, constraints) {
                                                          if (kDebugMode) {
                                                            debugPrint(
                                                              'twoColumnMode controlArea => size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                            );
                                                          }
                                                          return getControlArea(
                                                            portraitMode:
                                                                portraitMode,
                                                            showSwiper: false,
                                                            orientation:
                                                                orientation,
                                                            threeCols:
                                                                threeCols,
                                                            idle: idle,
                                                            shuffle: shuffle,
                                                            repeat: repeat,
                                                            isRadio: isRadio,
                                                            selectedZoneId:
                                                                selectedZoneId,
                                                          );
                                                        },
                                                      ),
                                                    ),

                                                    Container(
                                                      margin: EdgeInsets.only(
                                                        top: threeCols
                                                            ? coverPadding
                                                            : 0.0,

                                                        right: coverPadding,
                                                      ),
                                                      decoration:
                                                          Globals.brightness() ==
                                                              Brightness.dark
                                                          ? ColorDefs.areaDecorationFilledDarkStyle(
                                                              withAnimatedBackground:
                                                                  withAnimatedBackground,
                                                            )
                                                          : ColorDefs.areaDecorationFilledLightStyle(
                                                              withAnimatedBackground:
                                                                  withAnimatedBackground,
                                                            ),
                                                      child: LayoutBuilder(
                                                        builder: (context, constraints) {
                                                          double width =
                                                              constraints
                                                                  .maxWidth;
                                                          double height =
                                                              constraints
                                                                  .maxHeight;

                                                          WidgetsBinding.instance.addPostFrameCallback((
                                                            _,
                                                          ) {
                                                            final keyContext =
                                                                portraitTextAreaKey
                                                                    .currentContext;
                                                            if (keyContext !=
                                                                null) {
                                                              final box =
                                                                  keyContext
                                                                          .findRenderObject()
                                                                      as RenderBox;
                                                              width = box
                                                                  .size
                                                                  .width;
                                                              height = box
                                                                  .size
                                                                  .height;

                                                              if (kDebugMode) {
                                                                debugPrint(
                                                                  'twoColumnMode textarea => size: $width x $height',
                                                                );
                                                              }
                                                            }
                                                          });

                                                          return getTextArea(
                                                            key:
                                                                portraitTextAreaKey,
                                                            portraitMode:
                                                                portraitMode,
                                                            showSwiper:
                                                                showSwiper,
                                                            threeCols:
                                                                threeCols,
                                                            width: width,
                                                            height: height,
                                                            fontSize:
                                                                getTextAreaFontSize(
                                                                  showSwiper:
                                                                      false,
                                                                  threeCols:
                                                                      threeCols,
                                                                  width: width,
                                                                  height:
                                                                      height,
                                                                ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    if (showProgressBar == true)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              bottom:
                                                                  coverPadding,
                                                            ),
                                                        child: LayoutBuilder(
                                                          builder: (context, constraints) {
                                                            double width =
                                                                constraints
                                                                    .maxWidth;
                                                            return SizedBox(
                                                              width: width,
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets.only(
                                                                      right:
                                                                          coverPadding,
                                                                    ),
                                                                child: ProgressBarWidget(
                                                                  ip: ip,
                                                                  controlId:
                                                                      controlId,
                                                                  coverPadding:
                                                                      coverPadding,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                      if (threeCols)
                                        Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              top: threeCols
                                                  ? coverPadding
                                                  : 0.0,
                                              bottom: coverPadding,
                                              right: coverPadding,
                                            ),
                                            decoration:
                                                Globals.brightness() ==
                                                    Brightness.dark
                                                ? ColorDefs.areaDecorationFilledDarkStyle(
                                                    withAnimatedBackground:
                                                        withAnimatedBackground,
                                                  )
                                                : ColorDefs.areaDecorationFilledLightStyle(
                                                    withAnimatedBackground:
                                                        withAnimatedBackground,
                                                  ),
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                double width =
                                                    constraints.maxWidth;
                                                double height =
                                                    constraints.maxHeight;

                                                if (kDebugMode) {
                                                  debugPrint(
                                                    'threeColumnMode selectbox + textarea => size: ${constraints.maxWidth} x ${constraints.maxHeight}',
                                                  );
                                                }
                                                return Column(
                                                  mainAxisAlignment:
                                                      widget.controlId == null
                                                      ? MainAxisAlignment
                                                            .spaceBetween
                                                      : MainAxisAlignment
                                                            .center,
                                                  children: [
                                                    if (widget.controlId ==
                                                            null &&
                                                        threeCols)
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                          left: coverPadding,
                                                        ),
                                                        child: getSelectBoxArea(
                                                          portraitMode:
                                                              portraitMode,
                                                          threeCols: threeCols,
                                                          withLabel:
                                                              constraints
                                                                  .maxWidth >=
                                                              380,
                                                          width:
                                                              constraints
                                                                  .maxWidth -
                                                              30,
                                                          options: options,
                                                        ),
                                                      ),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          Expanded(
                                                            child: Padding(
                                                              padding: EdgeInsets.only(
                                                                top:
                                                                    coverPadding,
                                                                bottom:
                                                                    coverPadding,
                                                              ),
                                                              child: getTextArea(
                                                                key:
                                                                    portraitTextAreaKey,
                                                                portraitMode:
                                                                    portraitMode,
                                                                showSwiper:
                                                                    showSwiper,
                                                                threeCols:
                                                                    threeCols,
                                                                width: width,
                                                                height: height,
                                                                fontSize: getTextAreaFontSize(
                                                                  showSwiper:
                                                                      false,
                                                                  threeCols:
                                                                      threeCols,
                                                                  width: width,
                                                                  height:
                                                                      height,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (showProgressBar ==
                                                              true)
                                                            SizedBox(
                                                              width: width,
                                                              child: Padding(
                                                                padding: EdgeInsets.only(
                                                                  left:
                                                                      coverPadding,
                                                                  right:
                                                                      coverPadding,
                                                                  bottom:
                                                                      coverPadding,
                                                                ),
                                                                child: ProgressBarWidget(
                                                                  ip: ip,
                                                                  controlId:
                                                                      controlId,
                                                                  coverPadding:
                                                                      coverPadding,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (Globals.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: Globals.brightness(),
            middle: Text(title),
          ),
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
            body: body(context: context, mainBloc: mainBloc),
            resizeToFullWidth: () {
              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                minDesktopSize: minDesktopSize,
              );
            },
          )
        : PageWithToolbarFlutterStyle(
            scaffoldKey: scaffoldKey,
            translations: translations,
            title: title,
            sliderDefaultValue: 0.0,
            showSlider: false,
            showExpandableSpeedSlider: false,
            scrollSpeedDevice: 1.0,
            standardDesktopSize: standardDesktopSize,
            body: body(context: context, mainBloc: mainBloc),
            resizeToFullWidth: () {
              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                minDesktopSize: minDesktopSize,
              );
            },
          );
  }

  @override
  Future<void> dispose() async {
    mainBlocSubscription.cancel();

    super.dispose();
  }
}
