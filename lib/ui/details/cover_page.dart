import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final double fontSize = Globals.isDesktopDevice() ? 20.0 : 16.0;
  final double coveraPadding = 24.0;

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

  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : ${translations['coverPageHeaderText'] ?? 'Control'}';
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);

    super.initState();
  }

  Widget getTextArea() {
    if (selectedZone == null ||
        selectedZone!.isEmpty ||
        selectedZone!['cover'] == null) {
      return Row(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 104.0),
            child: Row(
              children: [
                Text(
                  '${translations['coverZoneHeader'] ?? 'Zone'}: ${(selectedZone?['server'] == 'roon' ? selectedZone!['zone'] : selectedZone!['server']).toString().toFirstUpper}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
                Text(
                  ' (${translations['inactive'] ?? 'inactive zone'})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
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

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, right: 16.0, bottom: 16.0),
                child: CoverTextOverlayExtended(
                  coverModel: coverModel,
                  fontSize: fontSize,
                  color: Colors.black,
                  translations: translations,
                  coverRowArtist: true,
                  coverRowAlbum: true,
                  coverRowTrack: true,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox();
  }

  Widget getSelectBoxArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Padding(
        padding: const EdgeInsets.only(right: 64.0),
        child: SelectBox(
            key: ValueKey('ZoneSelectBox$selectedZoneId'),
            translations: translations,
            aligned: 'horizontal',
            label: '${translations['zoneSelectionLabel'] ?? 'Zone'}:',
            labelColor: Colors.black,
            placeholder:
                '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
            inRow: false,
            noVerticalSpace: false,
            readOnly: false,
            selected: selectedZoneId,
            options: options,
            onChanged: (String? newValue) {
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
                    setState(() {
                      controlId = selectedControlId;
                      selectedZone = zone;
                      selectedZoneId = newValue;
                    });
                  }
                }
              }
            }),
      ),
    );
  }

  Widget body({
    required BuildContext context,
    required MainBloc mainBloc,
  }) =>
      SizedBox(
        child: Stack(
          children: [
            Column(
              children: [
                BlocBuilder(
                    bloc: mainBloc,
                    builder: (context, MainState mainState) {
                      if (mainState is MainStateLoaded) {
                        info = mainState.info[ip] ?? {};
                        macosVersion = mainState.macosVersion;

                        if (widget.controlId == null) {
                          Map<String, String> optionsUpdated =
                              mainBloc.generateZoneSelectionOptionsAndPreselect(
                            info: info,
                            controlId: controlId,
                            setZoneId: ({required String zoneId}) {
                              SchedulerBinding.instance
                                  .addPostFrameCallback((_) async {
                                if (mounted) {
                                  setState(() => selectedZoneId = zoneId);
                                }
                              });
                            },
                          );

                          if (options.keys.join(',') !=
                                  optionsUpdated.keys.join(',') ||
                              options.values.join(',') !=
                                  optionsUpdated.values.join(',')) {
                            SchedulerBinding.instance
                                .addPostFrameCallback((_) async {
                              if (mounted) {
                                setState(() {
                                  options = optionsUpdated;
                                });
                              }
                            });
                          }
                        }

                        if (info != {} && info['control_id'] != null) {
                          String? controlIdUpdated =
                              widget.controlId ?? info['control_id'];

                          if (info['web_playouts_raw'] != webPlayoutsRaw ||
                              info['roon_playouts_raw'] != roonPlayoutsRaw ||
                              controlId == null ||
                              controlIdUpdated != controlId) {
                            Map<String, dynamic> data =
                                mainBloc.getZoneDataForControlId(
                              info: info,
                              controlId: controlIdUpdated,
                              isRadio: isRadio,
                            );
                            Map<String, dynamic>? zone = data['zone'];
                            isRadio = data['isRadio'];

                            if (selectedZone?['zone'] == 'Apple Music') {
                              isRadio =
                                  false; // fix for AppleMusic because the delay is too big (every stream with position:0 will be disabling the prev/next button for isRadio == true, but the next infodata update will be loaded 10-15sec later)
                            }

                            if (zone != null) {
                              selectedZone = zone;
                            }

                            SchedulerBinding.instance
                                .addPostFrameCallback((_) async {
                              if (mounted) {
                                setState(() {
                                  webPlayoutsRaw = info['web_playouts_raw'];
                                  roonPlayoutsRaw = info['roon_playouts_raw'];
                                  if (controlIdUpdated != controlId) {
                                    controlId = controlIdUpdated;
                                  }
                                  if (zone != null) {
                                    selectedZone = zone;
                                    selectedZoneId = zone['server'] == 'roon'
                                        ? zone['zone']
                                        : '${zone['server']}-${zone['zone']}';
                                  }
                                });
                              }
                            });

                            if (controlIdUpdated != null) {
                              if ((info['shufflemode'] as Map<String, dynamic>)
                                  .containsKey(controlIdUpdated)) {
                                shuffle = info['shufflemode']
                                        [controlIdUpdated] ==
                                    'shuffle';
                              }
                              if ((info['repeatmode'] as Map<String, dynamic>)
                                  .containsKey(controlIdUpdated)) {
                                repeat = info['repeatmode'][controlIdUpdated] ==
                                    'repeat';
                              }
                              if ((info['playmode'] as Map<String, dynamic>)
                                  .containsKey(controlIdUpdated)) {
                                idle = info['playmode'][controlIdUpdated] !=
                                    'play';
                              }
                            }
                          }
                        }
                      }

                      return const SizedBox();
                    }),
                Expanded(
                  child: RoonmatrixAnimatedGradient(
                    child: OrientationBuilder(builder:
                        (BuildContext context, Orientation orientation) {
                      final bool portraitMode = (Globals.isMobileDevice() &&
                              orientation == Orientation.portrait) ||
                          (Globals.isDesktopDevice() &&
                              MediaQuery.of(context).size.height >
                                  MediaQuery.of(context).size.width);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (portraitMode == true && widget.controlId == null)
                            getSelectBoxArea(),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: NotificationListener<
                                      SizeChangedLayoutNotification>(
                                    onNotification: (notification) {
                                      build(context);
                                      return false;
                                    },
                                    child: SizeChangedLayoutNotifier(
                                      child: Container(
                                        padding: EdgeInsets.all(coveraPadding),
                                        child: AnimatedSwitcher(
                                          duration: Globals
                                              .coverSwitchDefaultFadeAnimationDuration,
                                          child:
                                              mainRepository.coverExistInZone(
                                                      zone: selectedZone)
                                                  ? Image.network(
                                                      selectedZone!['cover'],
                                                      key: ValueKey(
                                                          'BigCover${selectedZone!['cover']}'),
                                                      fit: BoxFit.contain,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    )
                                                  : SvgPicture.asset(
                                                      Globals
                                                          .placeholderAssetPath(),
                                                      allowDrawingOutsideViewBox:
                                                          false,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (portraitMode == false)
                                  Flexible(
                                    fit: FlexFit.tight,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (widget.controlId == null)
                                          getSelectBoxArea(),
                                        Expanded(
                                          child: ControlButtons(
                                            key: ValueKey(
                                                'ControButtonsDesktop-$idle-$shuffle-$repeat-$isRadio'),
                                            orientation: orientation,
                                            translations: translations,
                                            partsToSubtract: 275,
                                            ip: ip,
                                            controlId: controlId ??
                                                widget.controlId ??
                                                '',
                                            idle: idle,
                                            shuffle: shuffle,
                                            repeat: repeat,
                                            isRadio: isRadio,
                                            readOnly: selectedZoneId == null ||
                                                selectedZoneId!.isEmpty,
                                          ),
                                        ),
                                        getTextArea(),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
                          if (portraitMode == true)
                            Row(
                              children: [
                                Expanded(child: getTextArea()),
                                ControlButtons(
                                  key: ValueKey(
                                      'ControButtonsPortrait-$idle-$shuffle-$repeat-$isRadio'),
                                  orientation: orientation,
                                  translations: translations,
                                  partsToSubtract:
                                      MediaQuery.of(context).size.height - 150,
                                  ip: ip,
                                  controlId:
                                      controlId ?? widget.controlId ?? '',
                                  idle: idle,
                                  shuffle: shuffle,
                                  repeat: repeat,
                                  isRadio: isRadio,
                                  readOnly: selectedZoneId == null ||
                                      selectedZoneId!.isEmpty,
                                ),
                              ],
                            ),
                        ],
                      );
                    }),
                  ),
                ),
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
}
