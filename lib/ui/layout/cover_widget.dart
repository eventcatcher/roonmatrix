import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/layout/cover_overlay_button.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_small.dart';
import 'package:roonmatrix/ui/layout/zone_corner_label.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class CoverWidget extends StatefulWidget {
  final Map<String, dynamic> translations;
  final List<String> devices;
  final String? activeDeviceIp;
  final CoverModel coverModel;
  final double coverSize;
  final bool coverRowDynamicSize;
  final Orientation orientation;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const CoverWidget({
    super.key,
    required this.translations,
    required this.devices,
    required this.activeDeviceIp,
    required this.coverModel,
    required this.coverSize,
    required this.coverRowDynamicSize,
    required this.orientation,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<CoverWidget> createState() => _CoverWidgetState();
}

class _CoverWidgetState extends State<CoverWidget> {
  Map<String, dynamic> get translations => widget.translations;
  List<String> get devices => widget.devices;
  bool get coverRowDynamicSize => widget.coverRowDynamicSize;
  Orientation get orientation => widget.orientation;
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final double minPlayControlCoverSize = 150;
  final double extendedTextMinCoverHeight = 400.0;
  final Color textAreaBackgroundColor = Color.fromARGB(200, 0, 0, 0);
  final double zoneCornerLabelOpacity = 0.7;
  final int buttonStatusSwitchTimeoutInSeconds = 10;

  Timer? statusInProgressTimer;
  String statusInProgress = '';
  dynamic img;

  late MainRepository mainRepository;
  late MainBloc mainBloc;
  late double coverSize;
  late CoverModel coverModel;
  late String? activeDeviceIp;

  @override
  void initState() {
    super.initState();

    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    coverModel = widget.coverModel;
    coverSize = widget.coverSize;
    activeDeviceIp = widget.activeDeviceIp;

    img = NetworkImage(
      coverModel.coverUrl,
    );
  }

  @override
  void didUpdateWidget(CoverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    coverModel = widget.coverModel;

    if (statusInProgress == coverModel.status) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          setState(() {
            statusInProgress = '';
            if (statusInProgressTimer != null &&
                statusInProgressTimer!.isActive) {
              statusInProgressTimer!.cancel();
            }
          });
        }
      });
    }
    coverSize = widget.coverSize;
    activeDeviceIp = widget.activeDeviceIp;
  }

  bool get statusUpdateInProgress =>
      statusInProgress.isNotEmpty && statusInProgress != coverModel.status;

  Alignment getProgressIndicatorAlignment(String status) {
    if (status == 'previous') {
      return Alignment.centerLeft;
    }
    if (status == 'next') {
      return Alignment.centerRight;
    }
    return Alignment.center;
  }

  void setButtonStatusSwitchInProgressTimer() {
    statusInProgressTimer = Timer.periodic(
        Duration(seconds: buttonStatusSwitchTimeoutInSeconds), (Timer timer) {
      statusInProgress = '';
      statusInProgressTimer!.cancel();
    });
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          constraints: coverRowDynamicSize
              ? null
              : BoxConstraints(
                  maxWidth: coverSize,
                  maxHeight: coverSize,
                ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // constraints.maxHeight gets the height of the AnimatedList
              double coverHeight = constraints.maxHeight;
              double coverWidth = coverHeight;

              return Stack(
                children: [
                  InkWell(
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: 'Dialog',
                        transitionDuration: const Duration(milliseconds: 0),
                        pageBuilder: (_, __, ___) {
                          return CoverPage(
                            name: coverModel.zoneName,
                            ip: activeDeviceIp ?? devices[0],
                            controlId: coverModel.controlId,
                            translations: translations,
                            minDesktopSize: minDesktopSize,
                            standardDesktopSize: standardDesktopSize,
                          );
                        },
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 1.0),
                      width: coverWidth,
                      height: coverHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: AnimatedSwitcher(
                          duration:
                              Globals.coverSwitchDefaultFadeAnimationDuration,
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child: coverModel.coverUrl.isNotEmpty
                              ? Stack(
                                  children: [
                                    Container(
                                      key: ValueKey(
                                          'CoverWidgetImage-${coverModel.hash}-${orientation.name}'),
                                      width: coverRowDynamicSize
                                          ? double.infinity
                                          : null,
                                      height: coverRowDynamicSize
                                          ? double.infinity
                                          : null,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          colorFilter: coverModel.status !=
                                                  'playing'
                                              ? ColorDefs.idleZoneColorFilter
                                              : null,
                                          image: img,
                                          onError: (Object errDetails,
                                              StackTrace? trace) {
                                            setState(() {
                                              img = AssetImage(Globals
                                                  .placeholderPngAssetPath());
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    if (Globals.isDesktopDevice() &&
                                        coverWidth > minPlayControlCoverSize &&
                                        !coverModel.isRadio &&
                                        activeDeviceIp != null &&
                                        statusUpdateInProgress)
                                      Padding(
                                        padding:
                                            statusInProgress == 'previous' ||
                                                    statusInProgress == 'next'
                                                ? statusInProgress == 'previous'
                                                    ? const EdgeInsets.only(
                                                        left: 4.0)
                                                    : const EdgeInsets.only(
                                                        right: 4.0)
                                                : EdgeInsets.zero,
                                        child: Align(
                                          alignment:
                                              getProgressIndicatorAlignment(
                                            statusInProgress,
                                          ),
                                          child: SizedBox(
                                            width: 16 +
                                                coverWidth *
                                                    Globals
                                                        .overlyPlayoutButtonSizeFactor,
                                            height: 16 +
                                                coverWidth *
                                                    Globals
                                                        .overlyPlayoutButtonSizeFactor,
                                            child: CircularProgressIndicator(
                                              color: ColorDefs.blueIconColor(
                                                  context: context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (activeDeviceIp != null &&
                                        coverWidth > minPlayControlCoverSize &&
                                        (Globals.isDesktopDevice() ||
                                            coverModel.status != 'playing'))
                                      CoverOverlayButton(
                                        alignment: Alignment.center,
                                        coverWidth: coverWidth,
                                        additionalVisibility:
                                            (statusUpdateInProgress &&
                                                    (statusInProgress ==
                                                            'playing' ||
                                                        statusInProgress ==
                                                            'pause')) ||
                                                coverModel.status != 'playing',
                                        icon: coverModel.status == 'playing'
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
                                        message: coverModel.status == 'playing'
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
                                                  coverModel.status == 'pause'
                                                      ? 'playing'
                                                      : 'pause';
                                            });
                                            mainBloc.zoneControl(
                                              ip: mainBloc
                                                  .state.activeDeviceIp!,
                                              controlId: coverModel.controlId,
                                              cmd: 'playmode',
                                              enable: coverModel.status !=
                                                  'playing',
                                            );
                                          }
                                        },
                                      ),
                                    if (Globals.isDesktopDevice() &&
                                        coverWidth > minPlayControlCoverSize &&
                                        !coverModel.isRadio &&
                                        coverModel.status == 'playing' &&
                                        activeDeviceIp != null) ...[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 4.0),
                                        child: CoverOverlayButton(
                                            alignment: Alignment.centerLeft,
                                            coverWidth: coverWidth,
                                            additionalVisibility:
                                                statusUpdateInProgress &&
                                                    statusInProgress ==
                                                        'previous',
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
                                                  coverModel.status ==
                                                      'playing') {
                                                setButtonStatusSwitchInProgressTimer();
                                                setState(() {
                                                  statusInProgress = 'previous';
                                                });
                                                mainBloc.zoneControl(
                                                  ip: activeDeviceIp!,
                                                  controlId:
                                                      coverModel.controlId,
                                                  cmd: 'previous',
                                                  enable: true,
                                                );
                                              }
                                            }),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: CoverOverlayButton(
                                          alignment: Alignment.centerRight,
                                          coverWidth: coverWidth,
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
                                                coverModel.status ==
                                                    'playing') {
                                              setButtonStatusSwitchInProgressTimer();
                                              setState(() {
                                                statusInProgress = 'next';
                                              });
                                              mainBloc.zoneControl(
                                                ip: activeDeviceIp!,
                                                controlId: coverModel.controlId,
                                                cmd: 'next',
                                                enable: true,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Stack(
                                  children: [
                                    SvgPicture.asset(
                                      Globals.placeholderSvgAssetPath(),
                                      colorFilter:
                                          ColorDefs.idleZoneColorFilter,
                                      allowDrawingOutsideViewBox: false,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 60.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: zoneCornerLabelOpacity,
                    child: SizedBox(
                      width: coverWidth,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: ZoneCornerLabel(
                          zoneName: coverModel.zoneName,
                          coverWidth: coverWidth,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: coverWidth - 14,
                        ),
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: Globals.borderRadius(),
                          color: textAreaBackgroundColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 2.0),
                          child: coverHeight >= extendedTextMinCoverHeight &&
                                  (coverRowArtist == true ||
                                      coverRowAlbum == true)
                              ? CoverTextOverlayExtended(
                                  coverModel: coverModel,
                                  translations: translations,
                                  coverRowArtist: coverRowArtist,
                                  coverRowAlbum: coverRowAlbum,
                                  coverRowTrack: coverRowTrack,
                                )
                              : CoverTextOverlaySmall(
                                  coverModel: coverModel,
                                  coverRowTrack: coverRowTrack,
                                  constraints: constraints,
                                  translations: translations,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
