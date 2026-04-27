import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/spotify_connect_web_auth_page.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';
import 'package:roonmatrix/ui/layout/page_button.dart';

class MobilePageButtons extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, dynamic> translations;
  final bool moreInfo;
  final String zoneName;
  final String ip;
  final String spotifyAuthUrl;
  final Map<String, dynamic> zoneData;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final Function({required bool mode}) isExpanded;
  final Function({required String url}) setSpotifyAuthRedirectUrl;

  const MobilePageButtons({
    super.key,
    required this.navigatorKey,
    required this.translations,
    required this.moreInfo,
    required this.zoneName,
    required this.ip,
    required this.spotifyAuthUrl,
    required this.zoneData,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.isExpanded,
    required this.setSpotifyAuthRedirectUrl,
  });

  @override
  State<MobilePageButtons> createState() => _MobilePageButtonsState();
}

class _MobilePageButtonsState extends State<MobilePageButtons> {
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;
  Map<String, dynamic> get translations => widget.translations;
  bool get moreInfo => widget.moreInfo;
  String get zoneName => widget.zoneName;
  String get ip => widget.ip;
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  Map<String, dynamic> get zoneData => widget.zoneData;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  Function({required bool mode}) get isExpanded => widget.isExpanded;
  Function({required String url}) get setSpotifyAuthRedirectUrl =>
      widget.setSpotifyAuthRedirectUrl;

  final double baseWidth = 100.0;
  final int animationSpeed = 400;

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
  }) => [
    if (spotifyAuthUrl != '*')
      PageButton(
        navigatorKey: navigatorKey,
        label:
            translations['spotifyConnectAuthText'] ??
            'Spotify Connect Authorize',
        icon: Icon(Icons.phone_locked, color: Colors.white),
        moreInfo: true,
        page: SpotifyConnectWebAuthPage(
          name: zoneData['name'],
          ip: ip,
          url: spotifyAuthUrl,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
          callbackUrl: ({required String url}) =>
              setSpotifyAuthRedirectUrl(url: url),
        ),
        expandableMenuController: expandableMenuController,
      ),
    PageButton(
      navigatorKey: navigatorKey,
      label: translations['configButtonText'] ?? 'Config',
      icon: Icon(Icons.handyman_outlined, color: Colors.white, size: 18),
      moreInfo: false,
      page: ConfigPage(
        name: zoneData['name'],
        ip: ip,
        minDesktopSize: minDesktopSize,
        standardDesktopSize: standardDesktopSize,
        close: () {
          Navigator.pop(context);
        },
      ),
      expandableMenuController: expandableMenuController,
    ),
    PageButton(
      navigatorKey: navigatorKey,
      label: translations['controlButtonText'] ?? 'Control',
      icon: Icon(Icons.control_camera, color: Colors.white),
      moreInfo: false,
      page: CoverPage(
        name: zoneData['name'],
        ip: ip,
        translations: translations,
        minDesktopSize: minDesktopSize,
        standardDesktopSize: standardDesktopSize,
      ),
      expandableMenuController: expandableMenuController,
    ),
    if (!zoneData.containsKey('display_cover') ||
        zoneData['display_cover'] == false)
      PageButton(
        navigatorKey: navigatorKey,
        label: translations['messageButtonText'] ?? 'Message',
        icon: Icon(Icons.message_outlined, color: Colors.white, size: 18),
        moreInfo: false,
        page: MessagePage(
          ip: ip,
          name: zoneData['name'],
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
        expandableMenuController: expandableMenuController,
      ),
    if (!zoneData.containsKey('display_cover') ||
        zoneData['display_cover'] == false)
      PageButton(
        navigatorKey: navigatorKey,
        label: translations['liveControlButtonText'] ?? 'Live Control',
        icon: Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
        moreInfo: false,
        page: LiveControlPage(
          ip: ip,
          name: zoneData['name'],
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
        expandableMenuController: expandableMenuController,
      ),
  ];

  List<Widget> mobilePageButtonsForDebugging({
    required String zoneName,
    required String ip,
    required String spotifyAuthUrl,
    required Map<String, dynamic> zoneData,
    required ExpandableMenuController? expandableMenuController,
  }) => [
    if (moreInfo == true) ...[
      PageButton(
        navigatorKey: navigatorKey,
        label: translations['infoButtonText'] ?? 'Monitoring',
        icon: Icon(Icons.info_outlined, color: Colors.white),
        moreInfo: true,
        page: InfoPage(
          name: zoneData['name'],
          ip: ip,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
        expandableMenuController: expandableMenuController,
      ),
      PageButton(
        navigatorKey: navigatorKey,
        label: translations['logButtonText'] ?? 'Log',
        icon: Icon(Icons.terminal, color: Colors.white, size: 22),
        moreInfo: true,
        page: LogPage(
          name: zoneData['name'],
          ip: ip,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
        expandableMenuController: expandableMenuController,
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width:
        baseWidth +
        Globals.mobileExpandableButtonSize * mobileButtonsList.length,
    height: Globals.mobileExpandableButtonSize,
    child: Stack(
      children: [
        Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: ExpandableMenu(
            key: ValueKey(
              'ExpandableMenu-$ip-$moreInfo',
            ), // main item expandable for mobile
            width: Globals.mobileExpandableButtonSize,
            height: Globals.mobileExpandableButtonSize,
            animationSpeed: animationSpeed,
            backgroundColor: ColorDefs.buttonRowBackgroundColor(
              context: context,
            ),
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
