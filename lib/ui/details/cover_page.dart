import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/control_buttons.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/zone_corner_label.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart'
    show MainState, MainStateLoaded;
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
  final double coverPadding = 16.0;
  final double controlAreaInCrossMinHeight = 150;
  final bool withAnimatedBackground = false;

  final BoxDecoration areaDecorationBorderStyle = BoxDecoration(
    borderRadius: Globals.borderRadius(),
    border: Border.all(color: Colors.black, width: 0, style: BorderStyle.solid),
  );

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
  double? coverWidth;

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

  initSubscription() {
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

  Widget getTextArea({
    required bool portraitMode,
    required bool threeCols,
    double? fontSize,
  }) {
    final CrossAxisAlignment textAlignment = CrossAxisAlignment.center;
    final double fontSizeFinal =
        fontSize ?? (Globals.isDesktopDevice() ? 20.0 : 12.0);

    if (selectedZone == null ||
        selectedZone!.isEmpty ||
        selectedZone!['cover'] == null) {
      // zone is inactive
      return Row(
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
                          fontSize: fontSizeFinal,
                          color: Globals.brightness() == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Text(
                        ' (${translations['inactive'] ?? 'inactive zone'})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizeFinal,
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
          ? '${(selectedZone!['server'] == 'roon' ? selectedZone!['zone'] : selectedZone!['server']).toString().toFirstUpper} ${idle ? ' (${translations['paused'] ?? 'paused'})' : ''}'
          : '';

      String hash = md5
          .convert(utf8.encode(
              '$zoneName-${selectedZone!['artist']}-${selectedZone!['album']}-${selectedZone!['track']}-${selectedZone!['status']}'))
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

      Widget inner = Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: textAlignment,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: Globals.borderRadius(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 2.0),
                      child: CoverTextOverlayExtended(
                        coverModel: coverModel,
                        fontSize: fontSizeFinal,
                        color: Globals.brightness() == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        translations: translations,
                        coverRowArtist: true,
                        coverRowAlbum: true,
                        coverRowTrack: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      return ClipRRect(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
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
                  key: ValueKey('Text-$hash'),
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    inner,
                  ],
                )
              : IntrinsicHeight(
                  key: ValueKey('Text-$hash'),
                  child: inner,
                ),
        ),
      );
    }

    return SizedBox();
  }

  Map<String, dynamic> updateZoneSelection({
    required String? newValue,
  }) {
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
            ip: ip, controlId: selectedControlId, cmd: 'switch');

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
      return {
        "selectedZoneId": null,
      };
    }

    return {};
  }

  Widget getSelectBoxArea({
    required bool portraitMode,
    required Map<String, String> options,
  }) {
    return Container(
      margin: EdgeInsets.only(
        top: coverPadding,
        right: coverPadding,
      ),
      decoration: Globals.brightness() == Brightness.dark
          ? areaDecorationFilledDarkStyle()
          : areaDecorationFilledLightStyle(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectBox(
                key: ValueKey('ZoneSelectBox-$selectedZoneId'),
                translations: translations,
                aligned: 'horizontal',
                label: '${translations['zoneSelectionLabel'] ?? 'Zone'}',
                labelWeight: FontWeight.bold,
                labelColor: Globals.brightness() == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                labelFontSize: 17.0,
                placeholder:
                    '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
                inRow: true,
                noVerticalSpace: false,
                readOnly: false,
                selected:
                    options[selectedZoneId] != null ? selectedZoneId : null,
                options: options,
                onChanged: (String? newValue) {
                  Map<String, dynamic> updateData =
                      updateZoneSelection(newValue: newValue);
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
                }),
          ],
        ),
      ),
    );
  }

  Widget getCoverArea({
    required BuildContext context,
    required bool portraitMode,
    required Map<String, dynamic>? selectedZone,
  }) =>
      NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          build(context);
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: portraitMode
                ? EdgeInsets.only(
                    right: coverPadding,
                    top: coverPadding,
                    bottom: coverPadding,
                  )
                : EdgeInsets.all(coverPadding),
            child: AnimatedSwitcher(
              duration: Globals.coverSwitchDefaultFadeAnimationDuration,
              child: mainRepository.coverExistInZone(zone: selectedZone)
                  ? Image.network(
                      selectedZone!['cover'],
                      key: ValueKey(
                          'BigCover-$selectedZone-${selectedZone['cover']}'),
                      fit: BoxFit.contain,
                      alignment: portraitMode
                          ? Alignment.topCenter
                          : Alignment.centerLeft,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(Globals.placeholderPngAssetPath());
                      },
                    )
                  : SvgPicture.asset(
                      Globals.placeholderSvgAssetPath(),
                      allowDrawingOutsideViewBox: false,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: portraitMode
                          ? Alignment.center
                          : Alignment.centerLeft,
                    ),
            ),
          ),
        ),
      );

  Widget getControlArea({
    required bool portraitMode,
    required Orientation orientation,
    required bool threeCols,
    required bool idle,
    required bool shuffle,
    required bool repeat,
    required bool isRadio,
    required String? selectedZoneId,
  }) =>
      LayoutBuilder(builder: (context, constraints) {
        double padding = portraitMode ? 0.0 : 16.0;
        double height = portraitMode
            ? (constraints.maxHeight - coverPadding + 3)
            : (constraints.maxHeight - coverPadding * 2 - 24);

        if (height < 57 && !threeCols) {
          return SizedBox();
        }
        return Container(
          width: portraitMode ? null : double.infinity,
          height: portraitMode || threeCols ? null : double.infinity,
          margin: portraitMode
              ? EdgeInsets.only(
                  right: coverPadding,
                  bottom: coverPadding,
                )
              : EdgeInsets.only(
                  right: coverPadding,
                  top: coverPadding,
                  bottom: coverPadding,
                ),
          decoration: Globals.brightness() == Brightness.dark
              ? areaDecorationFilledDarkStyle()
              : areaDecorationFilledLightStyle(),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: ControlButtons(
                key: ValueKey(
                    'ControButtonsDesktop-$idle-$shuffle-$repeat-$isRadio'),
                orientation: orientation,
                translations: translations,
                //partsToSubtract: portraitMode || threeCols ? 0 : 355,
                ip: ip,
                controlId: controlId ?? widget.controlId ?? '',
                idle: idle,
                shuffle: shuffle,
                repeat: repeat,
                isRadio: isRadio,
                readOnly: selectedZoneId == null || selectedZoneId.isEmpty,
              ),
            ),
          ),
        );
      });

  Widget body({
    required BuildContext context,
    required MainBloc mainBloc,
  }) =>
      SizedBox(
        child: Stack(
          children: [
            Column(
              children: [
                !loaded
                    ? SizedBox()
                    : Expanded(
                        child: RoonmatrixAnimatedGradient(
                          disabled: !withAnimatedBackground,
                          child: OrientationBuilder(builder:
                              (BuildContext context, Orientation orientation) {
                            final bool portraitMode =
                                (Globals.isMobileDevice() &&
                                        orientation == Orientation.portrait) ||
                                    (Globals.isDesktopDevice() &&
                                        MediaQuery.of(context).size.height >
                                            MediaQuery.of(context).size.width);

                            bool threeCols = MediaQuery.of(context).size.width /
                                    MediaQuery.of(context).size.height >
                                2.5;

                            return portraitMode
                                ? Container(
                                    //color: Colors.red,
                                    margin: EdgeInsets.only(
                                      left: coverPadding,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (widget.controlId == null)
                                          SizedBox(
                                            width: coverWidth != null
                                                ? coverWidth!
                                                : 200,
                                            child: getSelectBoxArea(
                                                portraitMode: portraitMode,
                                                options: options),
                                          ),
                                        Expanded(
                                          child: LayoutBuilder(
                                              builder: (context, constraints) {
                                            final double coverSize =
                                                constraints.maxWidth - 8;
                                            final double minControlsHeight = 86;
                                            double coverHeight = min(
                                              coverSize,
                                              constraints.maxHeight -
                                                  minControlsHeight,
                                            );
                                            if (coverHeight <
                                                MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2) {
                                              coverHeight =
                                                  MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      2;
                                            }

                                            coverWidth =
                                                coverHeight + coverPadding - 16;

                                            final controlsHeight = max(
                                                  minControlsHeight,
                                                  constraints.maxHeight -
                                                      coverSize -
                                                      8,
                                                ) -
                                                coverPadding;

                                            final controlsWidth = min(
                                              coverWidth! - coverPadding,
                                              MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  coverPadding * 2,
                                            );
                                            print(
                                                'controlsWidth: $controlsWidth');

                                            return Column(
                                              children: [
                                                Expanded(
                                                  child: getCoverArea(
                                                    context: context,
                                                    portraitMode: portraitMode,
                                                    selectedZone: selectedZone,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: controlsWidth +
                                                      coverPadding,
                                                  height:
                                                      controlsHeight.toDouble(),
                                                  child: getControlArea(
                                                    portraitMode: portraitMode,
                                                    orientation: orientation,
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
                                          }),
                                        ),
                                        Center(
                                          child: Container(
                                              width: coverWidth != null
                                                  ? (coverWidth! - coverPadding)
                                                  : 200,
                                              margin: EdgeInsets.only(
                                                bottom: coverPadding,
                                                right: coverPadding,
                                              ),
                                              decoration: Globals
                                                          .brightness() ==
                                                      Brightness.dark
                                                  ? areaDecorationFilledDarkStyle()
                                                  : areaDecorationFilledLightStyle(),
                                              child: getTextArea(
                                                portraitMode: portraitMode,
                                                threeCols: threeCols,
                                              )),
                                        ),
                                      ],
                                    ),
                                  )
                                : LayoutGrid(
                                    areas: threeCols
                                        ? 'cover controls text'
                                        : '''
                                    cover select
                                    cover controls
                                    cover text
                                  ''',
                                    columnSizes: threeCols
                                        ? [1.fr, 1.fr, 0.8.fr]
                                        : [
                                            1.fr,
                                            Globals.isDesktopDevice()
                                                ? 0.75.fr
                                                : 1.2.fr,
                                          ],
                                    rowSizes: threeCols
                                        ? [
                                            1.fr,
                                          ]
                                        : [
                                            auto,
                                            1.fr,
                                            auto,
                                          ],
                                    columnGap: 2,
                                    rowGap: 2,
                                    children: [
                                      getCoverArea(
                                        context: context,
                                        portraitMode: portraitMode,
                                        selectedZone: selectedZone,
                                      ).inGridArea('cover'),
                                      if (!threeCols)
                                        widget.controlId == null
                                            ? getSelectBoxArea(
                                                portraitMode: portraitMode,
                                                options: options,
                                              ).inGridArea('select')
                                            : SizedBox().inGridArea('select'),
                                      getControlArea(
                                        portraitMode: portraitMode,
                                        orientation: orientation,
                                        threeCols: threeCols,
                                        idle: idle,
                                        shuffle: shuffle,
                                        repeat: repeat,
                                        isRadio: isRadio,
                                        selectedZoneId: selectedZoneId,
                                      ).inGridArea('controls'),
                                      Container(
                                        margin: EdgeInsets.only(
                                          top: threeCols ? coverPadding : 0.0,
                                          bottom: coverPadding,
                                          right: coverPadding,
                                        ),
                                        decoration: Globals.brightness() ==
                                                Brightness.dark
                                            ? areaDecorationFilledDarkStyle()
                                            : areaDecorationFilledLightStyle(),
                                        child: threeCols
                                            ? LayoutBuilder(builder:
                                                (context, constraints) {
                                                return Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: constraints
                                                              .maxHeight /
                                                          12),
                                                  child: Column(
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
                                                              left:
                                                                  coverPadding),
                                                          child:
                                                              getSelectBoxArea(
                                                            portraitMode:
                                                                portraitMode,
                                                            options: options,
                                                          ),
                                                        ),
                                                      Padding(
                                                        padding: EdgeInsets.only(
                                                            bottom:
                                                                coverPadding),
                                                        child: getTextArea(
                                                          portraitMode:
                                                              portraitMode,
                                                          threeCols: threeCols,
                                                          fontSize: constraints
                                                                      .maxHeight <
                                                                  300
                                                              ? 14
                                                              : null,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              })
                                            : getTextArea(
                                                portraitMode: portraitMode,
                                                threeCols: threeCols,
                                              ),
                                      ).inGridArea('text')
                                    ],
                                  );
                          }),
                        ),
                      )
              ],
            ),
            ZoneCornerLabel(
              zoneName: '-${selectedZone?['zone'] ?? name}',
              coverWidth: Globals.zoneCornerFullSize,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (Globals.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: Globals.brightness(),
            middle: Text(
              title,
            ),
          ),
          child: SafeArea(
            child: body(context: context, mainBloc: mainBloc),
          ),
        ),
      );
    }

    return Globals.inMacosStyle()
        ? PageWithToolbarMacStyle(
            title: title,
            standardDesktopSize: standardDesktopSize,
            macosVersion: macosVersion,
            body: body(context: context, mainBloc: mainBloc),
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
            body: body(context: context, mainBloc: mainBloc),
            resizeToFullWidth: () {
              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                  minDesktopSize: minDesktopSize);
            },
          );
  }

  @override
  Future<void> dispose() async {
    mainBlocSubscription.cancel();

    super.dispose();
  }
}
