import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/spotify_connect_web_auth_page.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class MobilePageButtons extends StatefulWidget {
  final Map<String, dynamic> translations;
  final bool moreInfo;
  final String zoneName;
  final String ip;
  final String spotifyAuthUrl;
  final Map<String, dynamic> zoneData;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  //final Function getExpandableMenuController;
  final Function({required bool mode}) isExpanded;
  final Function({required String url}) setSpotifyAuthRedirectUrl;

  const MobilePageButtons({
    super.key,
    required this.translations,
    required this.moreInfo,
    required this.zoneName,
    required this.ip,
    required this.spotifyAuthUrl,
    required this.zoneData,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    //required this.getExpandableMenuController,
    required this.isExpanded,
    required this.setSpotifyAuthRedirectUrl,
  });

  @override
  State<MobilePageButtons> createState() => _MobilePageButtonsState();
}

class _MobilePageButtonsState extends State<MobilePageButtons> {
  Map<String, dynamic> get translations => widget.translations;
  bool get moreInfo => widget.moreInfo;
  String get zoneName => widget.zoneName;
  String get ip => widget.ip;
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  Map<String, dynamic> get zoneData => widget.zoneData;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  // Function get getExpandableMenuController =>
  //     widget.getExpandableMenuController;
  Function({required bool mode}) get isExpanded => widget.isExpanded;
  Function({required String url}) get setSpotifyAuthRedirectUrl =>
      widget.setSpotifyAuthRedirectUrl;

  List<Widget> mobileButtonsList = [];
  ExpandableMenuController? expandableMenuController;

  @override
  void initState() {
    generateButtons();
    super.initState();
  }

  @override
  void didUpdateWidget(MobilePageButtons oldWidget) {
    generateButtons();
    super.didUpdateWidget(oldWidget);
  }

  void generateButtons() {
    mobileButtonsList = [
      ...mobilePageButtonsForDebugging(
        zoneName: zoneName,
        ip: ip,
        spotifyAuthUrl: spotifyAuthUrl,
        zoneData: zoneData,
        expandableMenuController: expandableMenuController,
      ).reversed,
      ...mobilePageButtons(
        zoneName: zoneName,
        ip: ip,
        spotifyAuthUrl: spotifyAuthUrl,
        zoneData: zoneData,
        expandableMenuController: expandableMenuController,
      ).reversed,
    ];
  }

  List<Widget> mobilePageButtons({
    required String zoneName,
    required String ip,
    required String spotifyAuthUrl,
    required Map<String, dynamic> zoneData,
    required ExpandableMenuController? expandableMenuController,
  }) =>
      [
        if (spotifyAuthUrl != '*')
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel:
                                  translations['spotifyConnectAuthText'] ??
                                      'Spotify Connect Authorize',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return SpotifyConnectWebAuthPage(
                                  name: zoneData['name'],
                                  ip: ip,
                                  url: spotifyAuthUrl,
                                  callbackUrl: ({required String url}) =>
                                      setSpotifyAuthRedirectUrl(url: url),
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.phone_enabled,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (expandableMenuController != null) {
                  expandableMenuController.close();
                }
                Future<void>.delayed(Duration(milliseconds: 500))
                    .then((value) => mounted
                        ? showGeneralDialog(
                            context: context,
                            // barrierColor: Colors
                            //     .black12
                            //     .withOpacity(0.6), // Background color
                            barrierDismissible: false,
                            barrierLabel: 'Dialog',
                            transitionDuration: const Duration(milliseconds: 0),
                            pageBuilder: (_, __, ___) {
                              return ConfigPage(
                                name: zoneData['name'],
                                ip: ip,
                                minDesktopSize: minDesktopSize,
                                standardDesktopSize: standardDesktopSize,
                                close: () {
                                  Navigator.pop(context);
                                },
                              );
                            },
                          )
                        : null);
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (expandableMenuController != null) {
                  expandableMenuController.close();
                }
                Future<void>.delayed(Duration(milliseconds: 500))
                    .then((value) => mounted
                        ? showGeneralDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierLabel: 'Dialog',
                            transitionDuration: const Duration(milliseconds: 0),
                            pageBuilder: (_, __, ___) {
                              return CoverPage(
                                name: zoneData['name'],
                                ip: ip,
                                translations: translations,
                                minDesktopSize: minDesktopSize,
                                standardDesktopSize: standardDesktopSize,
                              );
                            },
                          )
                        : null);
              },
              icon: const Icon(
                Icons.control_camera,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!zoneData.containsKey('display_cover') ||
            zoneData['display_cover'] == false)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeBlue.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return MessagePage(
                                  ip: ip,
                                  name: zoneData['name'],
                                  minDesktopSize: minDesktopSize,
                                  standardDesktopSize: standardDesktopSize,
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.message_outlined,
                  color: Colors.white,
                  size: 19.0,
                ),
              ),
            ),
          ),
        if (!zoneData.containsKey('display_cover') ||
            zoneData['display_cover'] == false)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeBlue.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return LiveControlPage(
                                  ip: ip,
                                  name: zoneData['name'],
                                  minDesktopSize: minDesktopSize,
                                  standardDesktopSize: standardDesktopSize,
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ];

  List<Widget> mobilePageButtonsForDebugging({
    required String zoneName,
    required String ip,
    required String spotifyAuthUrl,
    required Map<String, dynamic> zoneData,
    required ExpandableMenuController? expandableMenuController,
  }) =>
      [
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return InfoPage(
                                  name: zoneData['name'],
                                  ip: ip,
                                  minDesktopSize: minDesktopSize,
                                  standardDesktopSize: standardDesktopSize,
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return LogPage(
                                  name: zoneData['name'],
                                  ip: ip,
                                  minDesktopSize: minDesktopSize,
                                  standardDesktopSize: standardDesktopSize,
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.terminal,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ];

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 100.0 + 38.0 * mobileButtonsList.length,
        height: 38.0,
        child: Stack(
          children: [
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: ExpandableMenu(
                key: ValueKey(
                    'ExpandableMenu$ip-$moreInfo'), // main item expandable for mobile
                width: 38.0,
                height: 38.0,
                animationSpeed: 400,
                backgroundColor:
                    SharedWidgets.buttonRowBackgroundColor(context: context),
                items: mobileButtonsList,
                getController: (ExpandableMenuController controller) {
                  expandableMenuController = controller;
                },
                isExpanded: (bool mode) => isExpanded(mode: mode),
              ),
            ),
          ],
        ),
      );
}
