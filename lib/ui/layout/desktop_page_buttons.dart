import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/spotify_connect_web_auth_page.dart';
import 'package:roonmatrix/ui/layout/page_button.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class DesktopPageButtons extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, dynamic> translations;
  final String ip;
  final Map<String, dynamic> info;
  final String spotifyAuthUrl;
  final bool moreInfo;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const DesktopPageButtons({
    super.key,
    required this.navigatorKey,
    required this.translations,
    required this.ip,
    required this.info,
    required this.spotifyAuthUrl,
    required this.moreInfo,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<DesktopPageButtons> createState() => DesktopPageButtonsState();
}

class DesktopPageButtonsState extends State<DesktopPageButtons> {
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;
  Map<String, dynamic> get translations => widget.translations;
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  bool get moreInfo => widget.moreInfo;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final double paddingLeft = 8.0;

  bool isMatrixDevice = false;
  bool isRaspberryPiDevice = true;
  bool isAppEmbedded = false;

  late MainBloc mainBloc;
  late String ip;
  late Map<String, dynamic> info;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    updateProperties();

    super.initState();
  }

  @override
  void didUpdateWidget(DesktopPageButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    updateProperties();
  }

  void updateProperties() {
    ip = widget.ip;
    info = widget.info;
    bool deviceSelectedAndReady = ip.isNotEmpty && info[ip] != null;

    if (deviceSelectedAndReady == true) {
      isMatrixDevice =
          (!(info[ip] as Map<String, dynamic>).containsKey('display_cover') ||
          info[ip]['display_cover'] == false);

      isRaspberryPiDevice =
          (!(info[ip] as Map<String, dynamic>).containsKey('is_raspberry_pi') ||
          ((info[ip] as Map<String, dynamic>).containsKey('is_raspberry_pi') &&
              info[ip]['is_raspberry_pi'] == true));

      isAppEmbedded =
          (info[ip] as Map<String, dynamic>).containsKey('is_app_embedded') &&
          info[ip]['is_app_embedded'] == true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!info.containsKey(ip)) {
      return SizedBox();
    }
    return Row(
      key: ValueKey('desktop-page-buttons-$ip-$spotifyAuthUrl'),
      children: [
        if (spotifyAuthUrl != '*')
          PageButton(
            navigatorKey: navigatorKey,
            label:
                translations['spotifyConnectAuthText'] ??
                'Spotify Connect Authorize',
            icon: Icon(Icons.phone_locked, color: Colors.white),
            moreInfo: true,
            page: SpotifyConnectWebAuthPage(
              name: info[ip]['name'],
              ip: ip,
              url: spotifyAuthUrl,
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
              callbackUrl: ({required String url}) {
                mainBloc.setSpotifyAuthRedirectUrl(ip: ip, url: url);
                if (navigatorKey.currentState != null &&
                    navigatorKey.currentState!.canPop()) {
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
        PageButton(
          navigatorKey: navigatorKey,
          label: translations['configButtonText'] ?? 'Config',
          icon: Icon(Icons.handyman_outlined, color: Colors.white, size: 20),
          moreInfo: false,
          page: ConfigPage(
            name: info[ip]['name'],
            ip: ip,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
            close: () {
              Navigator.pop(context);
            },
          ),
        ),
        PageButton(
          navigatorKey: navigatorKey,
          label: translations['controlButtonText'] ?? 'Control',
          icon: Icon(Icons.control_camera, color: Colors.white),
          moreInfo: false,
          page: CoverPage(
            name: info[ip]['name'],
            ip: ip,
            translations: translations,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        ),
        if ((isMatrixDevice == true && isRaspberryPiDevice == true) ||
            isAppEmbedded == true ||
            !isRaspberryPiDevice)
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['messageButtonText'] ?? 'Message',
            icon: Icon(Icons.message_outlined, color: Colors.white, size: 18.0),
            moreInfo: false,
            page: MessagePage(
              ip: ip,
              name: info[ip]['name'],
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
            ),
          ),
        if ((isMatrixDevice == true && isRaspberryPiDevice == true) ||
            isAppEmbedded == true ||
            !isRaspberryPiDevice)
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['liveControlButtonText'] ?? 'Live Control',
            icon: Icon(Icons.visibility_outlined, color: Colors.white),
            moreInfo: false,
            page: LiveControlPage(
              ip: ip,
              name: info[ip]['name'],
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
              isVirtualDevice: isAppEmbedded == true || !isRaspberryPiDevice,
            ),
          ),
        if (moreInfo == true) ...[
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['infoButtonText'] ?? 'Monitoring',
            icon: Icon(Icons.info_outlined, color: Colors.white),
            moreInfo: true,
            page: InfoPage(
              name: info[ip]['name'],
              ip: ip,
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
            ),
          ),
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['logButtonText'] ?? 'Log',
            icon: Icon(Icons.terminal, color: Colors.white),
            moreInfo: true,
            page: LogPage(
              name: info[ip]['name'],
              ip: ip,
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
            ),
          ),
        ],
      ],
    );
  }
}
