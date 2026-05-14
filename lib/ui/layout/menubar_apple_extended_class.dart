import 'dart:async';
import 'dart:io';

import 'package:enhanced_platform_menu/enhanced_platform_menu_icon.dart';
import 'package:enhanced_platform_menu/enhanced_platform_menu_item.dart';
import 'package:enhanced_platform_menu/sf_symbols.dart';
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

class MenubarAppleExtendedClass {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, dynamic> translations;
  final String aboutAppMessage;
  final MainBloc mainBloc;
  final SettingsBloc settingsBloc;
  final Function(BuildContext context) exportDeviceList;

  MenubarAppleExtendedClass({
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

  List<EnhancedPlatformMenuItemGroup> sharedViewItems({
    required BuildContext context,
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
    required Map<String, dynamic> spotifyAuthUrls,
    required bool deviceSelectedAndReady,
    required bool isMatrixDevice,
    required bool isRaspberryPiDevice,
    required bool isAppEmbedded,
  }) => [
    EnhancedPlatformMenuItemGroup(
      members: <PlatformMenuItem>[
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.toggleFullScreen,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.toggleFullScreen,
          ),
        EnhancedPlatformMenuItem(
          label: translations['backToMainViewLabel'] ?? 'Back to main page',
          icon: SFSymbolIcon(SFSymbols.backward),
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyB,
            control: true,
            shift: true,
          ),
          onSelected: () =>
              navigatorKey.currentState?.popUntil((route) => route.isFirst),
        ),
        EnhancedPlatformMenuItem(
          label:
              translations['selectDeviceBeforeLabel'] ??
              'Select previous device',
          icon: SFSymbolIcon(SFSymbols.arrow_up),
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyB,
            control: true,
            alt: true,
          ),
          onSelected: () => mainBloc.selectDeviceBefore(ip: selectedDeviceIp),
        ),
        EnhancedPlatformMenuItem(
          label: translations['selectDeviceNextLabel'] ?? 'Select next device',
          icon: SFSymbolIcon(SFSymbols.arrow_down),
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyN,
            control: true,
            alt: true,
          ),
          onSelected: () => mainBloc.selectDeviceNext(ip: selectedDeviceIp),
        ),
        if (Platform.isMacOS) ...[
          EnhancedPlatformMenuItem(
            label: translations['fullWidthResizeButtonLabel'] ?? 'Full width',
            icon: SFSymbolIcon(SFSymbols.arrow_left_and_right_square),
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyW,
              control: true,
            ),
            onSelected: () => mainBloc.windowResizeToFullWidthAndMinimumHeight(
              minDesktopSize: minDesktopSize,
            ),
          ),
          EnhancedPlatformMenuItem(
            label: translations['minimizeResizeButtonLabel'] ?? 'Minimize',
            icon: SFSymbolIcon(SFSymbols.minus_magnifyingglass),
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
            ),
            onSelected: () => windowManager.setSize(
              Size(Globals.minDesktopWidth, Globals.minDesktopHeight + 24),
              animate: true,
            ),
          ),
          EnhancedPlatformMenuItem(
            label: translations['mediumResizeButtonLabel'] ?? 'Medium size',
            icon: SFSymbolIcon(SFSymbols.magnifyingglass),
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyN,
              control: true,
            ),
            onSelected: () =>
                windowManager.setSize(standardDesktopSize, animate: true),
          ),
          EnhancedPlatformMenuItem(
            label: translations['maximizeResizeButtonLabel'] ?? 'Maximize',
            icon: SFSymbolIcon(SFSymbols.plus_magnifyingglass),
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
      EnhancedPlatformMenuItemGroup(
        members: <EnhancedPlatformMenuItem>[
          if ((spotifyAuthUrls[selectedDeviceIp] ?? '*') != '*')
            EnhancedPlatformMenuItem(
              label:
                  translations['spotifyConnectAuthText'] ??
                  'Spotify Connect Authorize',
              icon: SFSymbolIcon(SFSymbols.phone_connection),
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
          EnhancedPlatformMenuItem(
            label: translations['configButtonText'] ?? 'Config',
            icon: SFSymbolIcon(SFSymbols.square_and_pencil),
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
          EnhancedPlatformMenuItem(
            label: translations['controlButtonText'] ?? 'Control',
            icon: SFSymbolIcon(SFSymbols.cross),
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
              isAppEmbedded == true)
            EnhancedPlatformMenuItem(
              label: translations['messageButtonText'] ?? 'Message',
              icon: SFSymbolIcon(SFSymbols.captions_bubble),
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
          if (isMatrixDevice == true && isRaspberryPiDevice == true)
            EnhancedPlatformMenuItem(
              label: translations['liveControlButtonText'] ?? 'Live Control',
              icon: SFSymbolIcon(SFSymbols.slider_horizontal_2_square),
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
                ),
              ),
            ),
          EnhancedPlatformMenuItem(
            label: translations['infoButtonText'] ?? 'Monitoring',
            icon: SFSymbolIcon(SFSymbols.info_circle),
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
          EnhancedPlatformMenuItem(
            label: translations['logButtonText'] ?? 'Log',
            icon: SFSymbolIcon(SFSymbols.apple_terminal),
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
            EnhancedPlatformMenuItem(
              label: translations['miniPlayerPageHeaderText'] ?? 'Mini Player',
              icon: SFSymbolIcon(SFSymbols.music_note_tv),
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

  PlatformMenuBar appleMenubar({
    required BuildContext context,
    required bool isIPad,
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
            (info[selectedDeviceIp]['is_raspberry_pi'] == true));

    bool isAppEmbedded =
        deviceSelectedAndReady == true &&
        (info[selectedDeviceIp] as Map<String, dynamic>).containsKey(
          'is_app_embedded',
        ) &&
        info[selectedDeviceIp]['is_app_embedded'] == true;

    return PlatformMenuBar(
      menus: <EnhancedPlatformMenu>[
        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.application,
          label: title,
          menus: <PlatformMenuItem>[
            EnhancedPlatformMenuItemGroup(
              members: <EnhancedPlatformMenuItem>[
                EnhancedPlatformMenuItem(
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
            EnhancedPlatformMenuItemGroup(
              members: <EnhancedPlatformMenuItem>[
                EnhancedPlatformMenuItem(
                  label: translations['menuEntrySettings'] ?? 'Settings',
                  shortcut: SingleActivator(
                    isIPad ? LogicalKeyboardKey.keyS : LogicalKeyboardKey.comma,
                    meta: !isIPad,
                    control: isIPad,
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

            // EnhancedPlatformMenuItemGroup(
            //   members: <PlatformMenuItem>[
            //     if (PlatformProvidedMenuItem.hasMenu(
            //       PlatformProvidedMenuItemType.servicesSubmenu,
            //     ))
            //       const PlatformProvidedMenuItem(
            //         type: PlatformProvidedMenuItemType.servicesSubmenu,
            //       ),
            //   ],
            // ),
            EnhancedPlatformMenuItemGroup(
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
            EnhancedPlatformMenuItemGroup(
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
        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.file,
          label: translations['menuEntryFile'] ?? 'File',
          menus: [
            EnhancedPlatformMenuItemGroup(
              members: <EnhancedPlatformMenuItem>[
                EnhancedPlatformMenuItem(
                  label:
                      translations['menuEntryExportDeviceList'] ??
                      'Export Device List',
                  icon: SFSymbolIcon(SFSymbols.square_and_arrow_down),
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
        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.edit,
          label: translations['menuEntryEdit'] ?? 'Edit',
          menus: <PlatformMenuItem>[
            // EnhancedPlatformMenuItemGroup(
            //   members: <EnhancedPlatformMenuItem>[
            //     EnhancedPlatformMenuItem(
            //       label: translations['menuEntryUndo'] ?? 'Undo',
            //       shortcut: const SingleActivator(
            //         LogicalKeyboardKey.keyZ,
            //         meta: true,
            //       ),
            //       //onSelected: () {},
            //     ),
            //     EnhancedPlatformMenuItem(
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
            EnhancedPlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                EnhancedPlatformMenuItem(
                  label: translations['menuEntryCut'] ?? 'Cut',
                  icon: SFSymbolIcon(SFSymbols.scissors),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyX,
                    meta: true,
                  ),
                  onSelected: () => editingService.cut(),
                ),
                EnhancedPlatformMenuItem(
                  label: translations['menuEntryCopy'] ?? 'Copy',
                  icon: SFSymbolIcon(SFSymbols.document_on_document),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyC,
                    meta: true,
                  ),
                  onSelected: () => editingService.copy(),
                ),
                EnhancedPlatformMenuItem(
                  label: translations['menuEntryPaste'] ?? 'Paste',
                  icon: SFSymbolIcon(SFSymbols.document_on_clipboard),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyV,
                    meta: true,
                  ),
                  onSelected: () => editingService.paste(),
                ),
              ],
            ),
            EnhancedPlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                EnhancedPlatformMenuItem(
                  label: translations['menuEntrySelectAll'] ?? 'Select All',
                  //icon: SFSymbolIcon(SFSymbols.all),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    meta: true,
                  ),
                  onSelected: () => editingService.selectAll(),
                ),
              ],
            ),
            EnhancedPlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenu(
                  label: translations['menuEntrySpeach'] ?? 'Speach',
                  menus: <PlatformMenuItem>[
                    EnhancedPlatformMenuItemGroup(
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

        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.view,
          label: translations['menuEntryView'] ?? 'View',
          removeDefaultItems: isIPad,
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

        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.window,
          label: translations['menuEntryWindow'] ?? 'Window',
          menus: <PlatformMenuItem>[
            EnhancedPlatformMenuItemGroup(
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
            // EnhancedPlatformMenuItemGroup(
            //   members: <PlatformMenuItem>[
            //     if (PlatformProvidedMenuItem.hasMenu(
            //       PlatformProvidedMenuItemType.arrangeWindowsInFront,
            //     ))
            //       const PlatformProvidedMenuItem(
            //         type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
            //       ),
            //   ],
            // ),
          ],
        ),
        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.help,
          label: translations['menuEntryHelp'] ?? 'Help',
          menus: <PlatformMenuItem>[
            // EnhancedPlatformMenuItemGroup(
            //   members: <PlatformMenuItem>[
            //     PlatformMenuItem(
            //       label: translations['placeholderButtonText'] ?? 'placeholder',
            //       shortcut: const SingleActivator(
            //         LogicalKeyboardKey.keyP,
            //         control: true,
            //         shift: true,
            //         alt: true,
            //       ),
            //       onSelected: () {},
            //     ),
            //   ],
            // ),
          ],
        ),
      ],
      child: child,
    );
  }

  void dispose() {
    settingsStreamSubscription?.cancel();
  }
}
