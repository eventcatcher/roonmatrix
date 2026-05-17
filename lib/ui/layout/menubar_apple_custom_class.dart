import 'dart:async';
import 'dart:io';

import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/mini_player_page.dart';
import 'package:roonmatrix/ui/details/spotify_connect_web_auth_page.dart';
import 'package:roonmatrix/ui/helper/text_editing_service.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class MenubarAppleCustomClass {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, dynamic> translations;
  final String aboutAppMessage;
  final MainBloc mainBloc;
  final SettingsBloc settingsBloc;
  final Function(BuildContext context) exportDeviceList;

  MenubarAppleCustomClass({
    required this.standardDesktopSize,
    required this.minDesktopSize,
    required this.navigatorKey,
    required this.translations,
    required this.aboutAppMessage,
    required this.mainBloc,
    required this.settingsBloc,
    required this.exportDeviceList,
  });

  final String title = Globals.mainWindowTitle;

  bool miniPlayerAlwaysOnTop = true;
  bool miniPlayerPreventCloseApp = true;
  bool miniPlayerShowTextInfoOnTrackChange = true;
  int miniPlayerTextInfoDuration = 10;
  String selectedDeviceIp = '';

  StreamSubscription? settingsStreamSubscription;

  void init() {
    TextEditingService.instance.init();

    settingsStreamSubscription = settingsBloc.stream.listen((
      SettingsState settingsState,
    ) {
      if (settingsState is SettingsStateLoaded) {
        miniPlayerAlwaysOnTop = settingsBloc.state.miniPlayerAlwaysOnTop;
        miniPlayerPreventCloseApp =
            settingsBloc.state.miniPlayerPreventCloseApp;
        miniPlayerShowTextInfoOnTrackChange =
            settingsBloc.state.miniPlayerShowTextInfoOnTrackChange;
        miniPlayerTextInfoDuration =
            settingsBloc.state.miniPlayerTextInfoDuration;
      }
    });
  }

  List<PlatformMenuItemGroup> sharedViewItems({
    required BuildContext context,
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
    required Map<String, dynamic> spotifyAuthUrls,
    required bool deviceSelectedAndReady,
    required bool isMatrixDevice,
    required bool isRaspberryPiDevice,
    required bool isAppEmbedded,
  }) => [
    PlatformMenuItemGroup(
      members: <PlatformMenuItem>[
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.toggleFullScreen,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.toggleFullScreen,
          ),
        PlatformMenuItem(
          label: translations['backToMainViewLabel'] ?? 'Back to main page',
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyB,
            control: true,
            shift: true,
          ),
          onSelected: () =>
              navigatorKey.currentState?.popUntil((route) => route.isFirst),
        ),
        PlatformMenuItem(
          label:
              translations['selectDeviceBeforeLabel'] ??
              'Select previous device',
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyB,
            control: true,
            alt: true,
          ),
          onSelected: () => mainBloc.selectDeviceBefore(ip: selectedDeviceIp),
        ),
        PlatformMenuItem(
          label: translations['selectDeviceNextLabel'] ?? 'Select next device',
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyN,
            control: true,
            alt: true,
          ),
          onSelected: () => mainBloc.selectDeviceNext(ip: selectedDeviceIp),
        ),
        if (Platform.isMacOS) ...[
          PlatformMenuItem(
            label: translations['fullWidthResizeButtonLabel'] ?? 'Full width',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyW,
              control: true,
            ),
            onSelected: () => mainBloc.windowResizeToFullWidthAndMinimumHeight(
              minDesktopSize: minDesktopSize,
            ),
          ),
          PlatformMenuItem(
            label: translations['minimizeResizeButtonLabel'] ?? 'Minimize',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
            ),
            onSelected: () => windowManager.setSize(
              Size(Globals.minDesktopWidth, Globals.minDesktopHeight + 24),
              animate: true,
            ),
          ),
          PlatformMenuItem(
            label: translations['mediumResizeButtonLabel'] ?? 'Medium size',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyN,
              control: true,
            ),
            onSelected: () =>
                windowManager.setSize(standardDesktopSize, animate: true),
          ),
          PlatformMenuItem(
            label: translations['maximizeResizeButtonLabel'] ?? 'Maximize',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyM,
              control: true,
            ),
            onSelected: () => windowManager.maximize(),
          ),
        ],
      ],
    ),
    if (deviceSelectedAndReady == true)
      PlatformMenuItemGroup(
        members: <PlatformMenuItem>[
          if ((spotifyAuthUrls[selectedDeviceIp] ?? '*') != '*')
            PlatformMenuItem(
              label:
                  translations['spotifyConnectAuthText'] ??
                  'Spotify Connect Authorize',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyA,
                control: true,
                shift: true,
              ),
              onSelected: () => SharedWidgets.openPage(
                context: context,
                navigatorKey: navigatorKey,
                page: SpotifyConnectWebAuthPage(
                  name: info[selectedDeviceIp]['name'],
                  ip: selectedDeviceIp,
                  url: spotifyAuthUrls[selectedDeviceIp] ?? '*',
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                  callbackUrl: ({required String url}) {
                    mainBloc.setSpotifyAuthRedirectUrl(
                      ip: selectedDeviceIp,
                      url: url,
                    );
                    if (navigatorKey.currentState != null &&
                        navigatorKey.currentState!.canPop()) {
                      navigatorKey.currentState?.popUntil(
                        (route) => route.isFirst,
                      );
                    }
                  },
                ),
              ),
            ),
          PlatformMenuItem(
            label: translations['configButtonText'] ?? 'Config',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              control: true,
              shift: true,
            ),
            onSelected: () => SharedWidgets.openPage(
              context: context,
              navigatorKey: navigatorKey,
              page: ConfigPage(
                name: info[selectedDeviceIp]['name'],
                ip: selectedDeviceIp,
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
                close: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          PlatformMenuItem(
            label: translations['controlButtonText'] ?? 'Control',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyC,
              control: true,
              shift: true,
            ),
            onSelected: () => SharedWidgets.openPage(
              context: context,
              navigatorKey: navigatorKey,
              page: CoverPage(
                name: info[selectedDeviceIp]['name'],
                ip: selectedDeviceIp,
                translations: translations,
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
              ),
            ),
          ),
          if ((isMatrixDevice == true && isRaspberryPiDevice == true) ||
              isAppEmbedded == true ||
              !isRaspberryPiDevice)
            PlatformMenuItem(
              label: translations['messageButtonText'] ?? 'Message',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyM,
                control: true,
                shift: true,
              ),
              onSelected: () => SharedWidgets.openPage(
                context: context,
                navigatorKey: navigatorKey,
                page: MessagePage(
                  name: info[selectedDeviceIp]['name'],
                  ip: selectedDeviceIp,
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                ),
              ),
            ),
          if ((isMatrixDevice == true && isRaspberryPiDevice == true) ||
              isAppEmbedded == true ||
              !isRaspberryPiDevice)
            PlatformMenuItem(
              label: translations['liveControlButtonText'] ?? 'Live Control',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyL,
                control: true,
                shift: true,
              ),
              onSelected: () => SharedWidgets.openPage(
                context: context,
                navigatorKey: navigatorKey,
                page: LiveControlPage(
                  name: info[selectedDeviceIp]['name'],
                  ip: selectedDeviceIp,
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                  isVirtualDevice:
                      isAppEmbedded == true || !isRaspberryPiDevice,
                ),
              ),
            ),
          PlatformMenuItem(
            label: translations['infoButtonText'] ?? 'Monitoring',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyI,
              control: true,
              shift: true,
            ),
            onSelected: () => SharedWidgets.openPage(
              context: context,
              navigatorKey: navigatorKey,
              page: InfoPage(
                name: info[selectedDeviceIp]['name'],
                ip: selectedDeviceIp,
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
              ),
            ),
          ),
          PlatformMenuItem(
            label: translations['logButtonText'] ?? 'Log',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyD,
              control: true,
              shift: true,
            ),
            onSelected: () => SharedWidgets.openPage(
              context: context,
              navigatorKey: navigatorKey,
              page: LogPage(
                name: info[selectedDeviceIp]['name'],
                ip: selectedDeviceIp,
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
              ),
            ),
          ),
          if (Platform.isMacOS)
            PlatformMenuItem(
              label: translations['miniPlayerPageHeaderText'] ?? 'Mini Player',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyP,
                control: true,
                shift: true,
              ),
              onSelected: () {
                Map<String, dynamic> i = info[selectedDeviceIp];
                String controlId = i['control_id'];
                String zoneName = '-';
                if (i['channels'] != null && i['channels'][controlId] != null) {
                  if (i['channels'][controlId] == 'webserver' ||
                      i['channels'][controlId] == 'spotifyconnect') {
                    zoneName = controlId;
                  } else {
                    zoneName = i['channels'][controlId];
                  }
                }

                SharedWidgets.openPage(
                  context: context,
                  navigatorKey: navigatorKey,
                  page: MiniPlayerPage(
                    name: zoneName,
                    ip: selectedDeviceIp,
                    controlId: info['control_id'],
                    miniPlayerAlwaysOnTop: miniPlayerAlwaysOnTop,
                    miniPlayerPreventCloseApp: miniPlayerPreventCloseApp,
                    miniPlayerShowTextInfoOnTrackChange:
                        miniPlayerShowTextInfoOnTrackChange,
                    miniPlayerTextInfoDuration: miniPlayerTextInfoDuration,
                    translations: translations,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                  ),
                );
              },
            ),
        ],
      ),
  ];

  PlatformMenuBar macosMenubar({
    required BuildContext context,
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
    required Map<String, dynamic> spotifyAuthUrls,
    required Widget child,
  }) {
    final editingService = TextEditingService.instance;

    bool deviceSelectedAndReady =
        selectedDeviceIp.isNotEmpty && info[selectedDeviceIp] != null;

    bool isMatrixDevice =
        deviceSelectedAndReady == true &&
        (!(info[selectedDeviceIp] as Map<String, dynamic>).containsKey(
              'display_cover',
            ) ||
            info[selectedDeviceIp]['display_cover'] == false);

    bool isRaspberryPiDevice =
        deviceSelectedAndReady == true &&
        (!(info[selectedDeviceIp] as Map<String, dynamic>).containsKey(
              'is_raspberry_pi',
            ) ||
            info[selectedDeviceIp]['is_raspberry_pi'] == true);

    bool isAppEmbedded =
        deviceSelectedAndReady == true &&
        (info[selectedDeviceIp] as Map<String, dynamic>).containsKey(
          'is_app_embedded',
        ) &&
        info[selectedDeviceIp]['is_app_embedded'] == true;

    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: title,
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.about,
                ))
                  // const PlatformProvidedMenuItem(
                  //   type: PlatformProvidedMenuItemType.about,
                  // ),
                  PlatformMenuItem(
                    label:
                        translations['menuEntryAbout'] ??
                        'About ${Globals.mainWindowTitle}',
                    onSelected: () => SharedWidgets.openAboutModal(
                      context: context,
                      aboutAppMessage: aboutAppMessage,
                      translations: translations,
                    ),
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: translations['menuEntrySettings'] ?? 'Settings',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () {
                    showGeneralDialog(
                      context: context,
                      // barrierColor:
                      //     Colors.black12.withOpacity(0.6), // Background color
                      barrierDismissible: false,
                      barrierLabel: 'Dialog',
                      transitionDuration: const Duration(milliseconds: 0),
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return SettingsPage(
                              minDesktopSize: minDesktopSize,
                              standardDesktopSize: standardDesktopSize,
                            );
                          },
                    );
                  },
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.servicesSubmenu,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.servicesSubmenu,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.hide,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hide,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.hideOtherApplications,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hideOtherApplications,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.showAllApplications,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.showAllApplications,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.quit,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.quit,
                  ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: translations['menuEntryFile'] ?? 'File',
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label:
                      translations['menuEntryExportDeviceList'] ??
                      'Export Device List',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyE,
                    control: true,
                  ),
                  onSelected: () async => await exportDeviceList(context),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: translations['menuEntryEdit'] ?? 'Edit',
          menus: <PlatformMenuItem>[
            // PlatformMenuItemGroup(
            //   members: <PlatformMenuItem>[
            //     PlatformMenuItem(
            //       label: translations['menuEntryUndo'] ?? 'Undo',
            //       shortcut: const SingleActivator(
            //         LogicalKeyboardKey.keyZ,
            //         meta: true,
            //       ),
            //       //onSelected: () {},
            //     ),
            //     PlatformMenuItem(
            //       label: translations['menuEntryRedo'] ?? 'Redo',
            //       shortcut: const SingleActivator(
            //         LogicalKeyboardKey.keyZ,
            //         meta: true,
            //         shift: true,
            //       ),
            //       //onSelected: () {},
            //     ),
            //   ],
            // ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: translations['menuEntryCut'] ?? 'Cut',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyX,
                    meta: true,
                  ),
                  onSelected: () => editingService.cut(),
                ),
                PlatformMenuItem(
                  label: translations['menuEntryCopy'] ?? 'Copy',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyC,
                    meta: true,
                  ),
                  onSelected: () => editingService.copy(),
                ),
                PlatformMenuItem(
                  label: translations['menuEntryPaste'] ?? 'Paste',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyV,
                    meta: true,
                  ),
                  onSelected: () => editingService.paste(),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: translations['menuEntrySelectAll'] ?? 'Select All',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    meta: true,
                  ),
                  onSelected: () => editingService.selectAll(),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenu(
                  label: translations['menuEntrySpeach'] ?? 'Speach',
                  menus: <PlatformMenuItem>[
                    PlatformMenuItemGroup(
                      members: <PlatformMenuItem>[
                        if (PlatformProvidedMenuItem.hasMenu(
                          PlatformProvidedMenuItemType.startSpeaking,
                        ))
                          const PlatformProvidedMenuItem(
                            type: PlatformProvidedMenuItemType.startSpeaking,
                          ),
                        if (PlatformProvidedMenuItem.hasMenu(
                          PlatformProvidedMenuItemType.stopSpeaking,
                        ))
                          const PlatformProvidedMenuItem(
                            type: PlatformProvidedMenuItemType.stopSpeaking,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: translations['menuEntryView'] ?? 'View',
          menus: <PlatformMenuItem>[
            ...sharedViewItems(
              context: context,
              selectedDeviceIp: selectedDeviceIp,
              info: info,
              spotifyAuthUrls: spotifyAuthUrls,
              deviceSelectedAndReady: deviceSelectedAndReady,
              isMatrixDevice: isMatrixDevice,
              isRaspberryPiDevice: isRaspberryPiDevice,
              isAppEmbedded: isAppEmbedded,
            ),
          ],
        ),
        PlatformMenu(
          label: translations['menuEntryWindow'] ?? 'Window',
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.minimizeWindow,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.minimizeWindow,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.zoomWindow,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.zoomWindow,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.arrangeWindowsInFront,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
                  ),
              ],
            ),
          ],
        ),
        // PlatformMenu(
        //   label: translations['menuEntryHelp'] ?? 'Help',
        //   menus: <PlatformMenuItem>[
        //     PlatformMenuItemGroup(
        //       members: <PlatformMenuItem>[
        //         PlatformMenuItem(
        //           label: translations['placeholderButtonText'] ?? 'placeholder',
        //           shortcut: const SingleActivator(
        //             LogicalKeyboardKey.keyP,
        //             control: true,
        //             shift: true,
        //             alt: true,
        //           ),
        //           onSelected: () {},
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
      ],
      child: child,
    );
  }

  void dispose() {
    settingsStreamSubscription?.cancel();
  }
}
