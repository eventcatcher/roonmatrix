import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/spotify_connect_web_auth_page.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class DesktopPageButtons extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String ip;
  final Map<String, dynamic> info;
  final String spotifyAuthUrl;
  final bool moreInfo;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const DesktopPageButtons({
    super.key,
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
  Map<String, dynamic> get translations => widget.translations;
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  bool get moreInfo => widget.moreInfo;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

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
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButtonElement(
              label: translations['spotifyConnectAuthText'] ??
                  'Spotify Connect Authorize',
              noBackground: false,
              withCircle: true,
              moreInfo: true,
              icon: Icon(
                Icons.phone_enabled,
                color: Colors.white,
              ),
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return SpotifyConnectWebAuthPage(
                    name: info[ip]['name'],
                    ip: ip,
                    url: spotifyAuthUrl,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    callbackUrl: ({required String url}) {
                      mainBloc.setSpotifyAuthRedirectUrl(ip: ip, url: url);
                      Navigator.pop(context);
                    },
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButtonElement(
            label: translations['configButtonText'] ?? 'Config',
            noBackground: false,
            withCircle: true,
            icon: Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () => showGeneralDialog(
              context: context,
              // barrierColor: Colors
              //     .black12
              //     .withOpacity(0.6), // Background color
              barrierDismissible: false,
              barrierLabel: 'Dialog',
              transitionDuration: const Duration(milliseconds: 0),
              pageBuilder: (_, __, ___) {
                return ConfigPage(
                  name: info[ip]['name'],
                  ip: ip,
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                  close: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButtonElement(
            label: translations['controlButtonText'] ?? 'Control',
            noBackground: false,
            withCircle: true,
            icon: Icon(
              Icons.control_camera,
              color: Colors.white,
            ),
            onPressed: () => showGeneralDialog(
              context: context,
              barrierDismissible: false,
              barrierLabel: 'Dialog',
              transitionDuration: const Duration(milliseconds: 0),
              pageBuilder: (_, __, ___) {
                return CoverPage(
                  name: info[ip]['name'],
                  ip: ip,
                  translations: translations,
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                );
              },
            ),
          ),
        ),
        if (!info[ip].containsKey('display_cover') ||
            info[ip]['display_cover'] == false)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButtonElement(
              label: translations['messageButtonText'] ?? 'Message',
              noBackground: false,
              withCircle: true,
              icon: Icon(
                Icons.message_outlined,
                size: 18,
                color: Colors.white,
              ),
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return MessagePage(
                    ip: ip,
                    name: info[ip]['name'],
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        if (!info[ip].containsKey('display_cover') ||
            info[ip]['display_cover'] == false)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButtonElement(
              label: translations['liveControlButtonText'] ?? 'Live Control',
              noBackground: false,
              withCircle: true,
              icon: Icon(
                Icons.visibility_outlined,
                color: Colors.white,
              ),
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return LiveControlPage(
                    ip: ip,
                    name: info[ip]['name'],
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButtonElement(
              label: translations['infoButtonText'] ?? 'Monitoring',
              noBackground: false,
              withCircle: true,
              icon: Icon(
                Icons.info_outline,
                color: Colors.white,
              ),
              moreInfo: true,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return InfoPage(
                    name: info[ip]['name'],
                    ip: ip,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButtonElement(
              label: translations['logButtonText'] ?? 'Log',
              noBackground: false,
              withCircle: true,
              icon: Icon(Icons.terminal, color: Colors.white),
              moreInfo: true,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return LogPage(
                    name: info[ip]['name'],
                    ip: ip,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
