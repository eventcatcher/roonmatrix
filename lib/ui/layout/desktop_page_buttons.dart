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

  late MainBloc mainBloc;
  late String ip;
  late Map<String, dynamic> info;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    ip = widget.ip;
    info = widget.info;

    super.initState();
  }

  @override
  void didUpdateWidget(DesktopPageButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    ip = widget.ip;
    info = widget.info;
  }

  @override
  Widget build(BuildContext context) {
    if (!info.containsKey(ip)) {
      return SizedBox();
    }
    return Row(
      children: [
        if (spotifyAuthUrl != '*')
          PageButton(
            navigatorKey: navigatorKey,
            label:
                translations['spotifyConnectAuthText'] ??
                'Spotify Connect Authorize',
            icon: Icons.phone_enabled,
            moreInfo: true,
            page: SpotifyConnectWebAuthPage(
              name: info[ip]['name'],
              ip: ip,
              url: spotifyAuthUrl,
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
              callbackUrl: ({required String url}) {
                mainBloc.setSpotifyAuthRedirectUrl(ip: ip, url: url);
                Navigator.pop(context);
              },
            ),
          ),
        PageButton(
          navigatorKey: navigatorKey,
          label: translations['configButtonText'] ?? 'Config',
          icon: Icons.settings,
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
          icon: Icons.control_camera,
          moreInfo: false,
          page: CoverPage(
            name: info[ip]['name'],
            ip: ip,
            translations: translations,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        ),
        if (!info[ip].containsKey('display_cover') ||
            info[ip]['display_cover'] == false)
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['messageButtonText'] ?? 'Message',
            icon: Icons.message_outlined,
            iconSize: 18.0,
            moreInfo: false,
            page: MessagePage(
              ip: ip,
              name: info[ip]['name'],
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
            ),
          ),
        if (!info[ip].containsKey('display_cover') ||
            info[ip]['display_cover'] == false)
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['liveControlButtonText'] ?? 'Live Control',
            icon: Icons.visibility_outlined,
            moreInfo: false,
            page: LiveControlPage(
              ip: ip,
              name: info[ip]['name'],
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
            ),
          ),
        if (moreInfo == true) ...[
          PageButton(
            navigatorKey: navigatorKey,
            label: translations['infoButtonText'] ?? 'Monitoring',
            icon: Icons.info_outline,
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
            icon: Icons.terminal,
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
