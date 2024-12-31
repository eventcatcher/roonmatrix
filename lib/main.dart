import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:window_manager/window_manager.dart';

Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    makeTitlebarTransparent: true,
    toolbarStyle: NSWindowToolbarStyle.automatic,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  double minHeight = Platform.isWindows ? 352 : 320;
  if (Platform.isLinux) {
    minHeight = 416;
  }
  Size minDesktopSize = Size(1280, minHeight);
  Size standardDesktopSize = const Size(1280, 768);

  if (SharedWidgets.inMacosStyle()) {
    await _configureMacosWindowUtils();
  }

  runApp(RoonMatrix(
    minDesktopSize: minDesktopSize,
    standardDesktopSize: standardDesktopSize,
  ));

  Bloc.transformer = sequential<
      dynamic>(); // all bloc events strictly sequential (like mapEventToState in bloc prior v8)

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    doWhenWindowReady(() {
      appWindow.minSize = minDesktopSize;
      appWindow.size = standardDesktopSize;

      appWindow.show();
    });
    await windowManager.ensureInitialized();
  }
}

class RoonMatrix extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const RoonMatrix({
    super.key,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<RoonMatrix> createState() => RoonMatrixState();
}

class RoonMatrixState extends State<RoonMatrix> {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final FileRepository fileRepository = FileRepository();
  final String title = 'RoonMatrix';

  Map<String, dynamic> translations = {};
  String aboutAppMessage = '';
  bool translationsLoaded = false;
  bool saveIdle = false;

  Brightness? brightnessValue;

  late TranslationsBloc translationsBloc;
  late SettingsBloc settingsBloc;
  late MainBloc mainBloc;
  late String appVersionAndBuildNumber;

  PlatformMenuBar menubar(BuildContext context) => PlatformMenuBar(
        menus: <PlatformMenuItem>[
          PlatformMenu(
            label: title,
            menus: <PlatformMenuItem>[
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.about))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.about),
                ],
              ),
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  PlatformMenuItem(
                    label: translations['menuEntrySettings'] ?? 'Settings',
                    shortcut: const SingleActivator(LogicalKeyboardKey.comma,
                        meta: true),
                    onSelected: () {
                      showGeneralDialog(
                        context: context,
                        // barrierColor:
                        //     Colors.black12.withOpacity(0.6), // Background color
                        barrierDismissible: false,
                        barrierLabel: 'Dialog',
                        transitionDuration: const Duration(milliseconds: 0),
                        pageBuilder: (_, __, ___) {
                          return SettingsPage(
                            close: () {
                              Navigator.pop(context);
                            },
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
                      PlatformProvidedMenuItemType.servicesSubmenu))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.servicesSubmenu),
                ],
              ),
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.hide))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.hide),
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.hideOtherApplications))
                    const PlatformProvidedMenuItem(
                        type:
                            PlatformProvidedMenuItemType.hideOtherApplications),
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.showAllApplications))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.showAllApplications),
                ],
              ),
              PlatformMenuItemGroup(members: <PlatformMenuItem>[
                if (PlatformProvidedMenuItem.hasMenu(
                    PlatformProvidedMenuItemType.quit))
                  const PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.quit),
              ]),
            ],
          ),
          PlatformMenu(
            label: translations['menuEntryFile'] ?? 'File',
            menus: <PlatformMenuItem>[
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  PlatformMenuItem(
                    label: translations['menuEntryExportDeviceList'] ??
                        'Export Device List',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyE,
                        meta: true),
                    onSelected: () async => await exportDeviceList(context),
                  ),
                ],
              ),
            ],
          ),
          PlatformMenu(
            label: translations['menuEntryEdit'] ?? 'Edit',
            menus: <PlatformMenuItem>[
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  PlatformMenuItem(
                    label: translations['menuEntryUndo'] ?? 'Undo',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyZ,
                        meta: true),
                  ),
                  PlatformMenuItem(
                    label: translations['menuEntryRedo'] ?? 'Redo',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyZ,
                        meta: true, shift: true),
                  ),
                ],
              ),
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  PlatformMenuItem(
                    label: translations['menuEntryCut'] ?? 'Cut',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyX,
                        meta: true),
                  ),
                  PlatformMenuItem(
                    label: translations['menuEntryCopy'] ?? 'Copy',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyC,
                        meta: true),
                  ),
                  PlatformMenuItem(
                    label: translations['menuEntryPaste'] ?? 'Paste',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyV,
                        meta: true),
                  ),
                  PlatformMenuItem(
                    label: translations['menuEntryDelete'] ?? 'Delete',
                  ),
                ],
              ),
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  PlatformMenuItem(
                    label: translations['menuEntrySelectAll'] ?? 'Select All',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyA,
                        meta: true),
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
                              PlatformProvidedMenuItemType.startSpeaking))
                            const PlatformProvidedMenuItem(
                                type:
                                    PlatformProvidedMenuItemType.startSpeaking),
                          if (PlatformProvidedMenuItem.hasMenu(
                              PlatformProvidedMenuItemType.stopSpeaking))
                            const PlatformProvidedMenuItem(
                                type:
                                    PlatformProvidedMenuItemType.stopSpeaking),
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
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.toggleFullScreen))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.toggleFullScreen),
                ],
              ),
            ],
          ),
          PlatformMenu(
            label: translations['menuEntryWindow'] ?? 'Window',
            menus: <PlatformMenuItem>[
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.minimizeWindow))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.minimizeWindow),
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.zoomWindow))
                    const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.zoomWindow),
                ],
              ),
              PlatformMenuItemGroup(
                members: <PlatformMenuItem>[
                  if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.arrangeWindowsInFront))
                    const PlatformProvidedMenuItem(
                        type:
                            PlatformProvidedMenuItemType.arrangeWindowsInFront),
                ],
              ),
            ],
          ),
        ],
        child: StartPage(
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
          title: title,
        ),
      );

  @override
  void initState() {
    fileRepository.init();

    initializeDateFormatting('de_DE', null);

    translationsBloc = TranslationsBloc();
    settingsBloc = SettingsBloc();
    mainBloc = MainBloc(fileRepository: fileRepository);

    super.initState();
  }

  Future<void> exportDeviceList(BuildContext context) async {
    setState(() {
      saveIdle = true;
    });
    bool? valid = await mainBloc.exportDevicesData();
    setState(() {
      saveIdle = false;
    });
    if (valid == null) {
      return;
    }
    if (valid == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              translations['exportDoneMessage'] ?? 'export successfully done'),
          backgroundColor: Colors.green,
        ));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(translations['exportFailedMessage'] ?? 'export failed!'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  List<BarButton> menuBarButtons(
      {required BuildContext context,
      required Map<String, dynamic> translations}) {
    return [
      BarButton(
        text: const Text(
          'File',
          style: TextStyle(color: Colors.white),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () async => await exportDeviceList(context),
              shortcutText: 'Ctrl+E',
              shortcut:
                  const SingleActivator(LogicalKeyboardKey.keyE, control: true),
              text: Text(translations['menuEntryExportDeviceList'] ??
                  'Export Device List'),
              icon: const Icon(Icons.settings),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () => showGeneralDialog(
                context: context,
                // barrierColor:
                //     Colors.black12.withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return SettingsPage(
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              shortcutText: 'Ctrl+,',
              shortcut: const SingleActivator(LogicalKeyboardKey.comma,
                  control: true),
              text: Text(translations['menuEntrySettings'] ?? 'Settings'),
              icon: const Icon(Icons.settings),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () {
                SharedWidgets.showPlatformSpecificDialog(
                    context: context,
                    child: (BuildContext context) => AlertElement(
                          title: translations['dialogQuitQuestion'] ??
                              'Do you really want to quit?',
                          button1Label: translations['dialogQuitYes'] ?? 'Yes',
                          onPressed1: () => FlutterWindowClose.closeWindow(),
                          button2Label: translations['dialogQuitNo'] ?? 'No',
                          onPressed2: () => Navigator.of(context).pop(false),
                        ));
              },
              shortcut:
                  const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
              shortcutText: 'Ctrl+Q',
              text: Text(translations['menuEntryQuit'] ?? 'Quit'),
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
      ),
      BarButton(
        text: Text(
          translations['menuEntryHelp'] ?? 'Help',
          style: const TextStyle(color: Colors.white),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () => mainBloc.openAboutModal(
                  context: context,
                  aboutAppMessage: aboutAppMessage,
                  translations: translations),
              icon: const Icon(Icons.info),
              text: Text(translations['menuEntryAbout'] ?? 'About'),
            ),
          ],
        ),
      ),
    ];
  }

  TabBarTheme tabBarTheme = const TabBarTheme(
      labelColor: Colors.white,
      dividerColor: Colors.grey,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2, color: Colors.red)));

  translationsLoadingWindow({required String title}) {
    if (SharedWidgets.inIosStyle()) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          brightness: SharedWidgets.brightness(),
          middle: Text(title),
        ),
        child: SizedBox(),
      );
    }

    return SharedWidgets.inMacosStyle()
        ? MacosScaffold(
            children: [
              ContentArea(
                builder: ((context, scrollController) {
                  return Material(
                    child: MacosWindow(
                      child: SizedBox(),
                    ),
                  );
                }),
              ),
            ],
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: const [],
            ),
            body: const SizedBox(),
          );
  }

  ThemeData materialThemeData({required TabBarTheme tabBarTheme}) => ThemeData(
        useMaterial3: false,
        tabBarTheme: tabBarTheme,
      );

  MenuBarWidget windowsLinuxMenuBar(
          {required BuildContext context,
          required Map<String, dynamic> translations}) =>
      MenuBarWidget(
        // Add a list of [BarButton]. The buttons in this List are
        // displayed as the buttons on the bar itself
        barButtons:
            menuBarButtons(context: context, translations: translations),

        // Style the menu bar itself. Hover over [MenuStyle] for all the options
        barStyle: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(Color(0xFF2b2b2b)),
          maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
        ),

        // Style the menu bar buttons. Hover over [ButtonStyle] for all the options
        barButtonStyle: const ButtonStyle(
          padding:
              WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6.0)),
          minimumSize: WidgetStatePropertyAll(Size(0.0, 32.0)),
        ),

        // Style the menu and submenu buttons. Hover over [ButtonStyle] for all the options
        menuButtonStyle: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(36.0)),
          padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0)),
        ),

        // Enable or disable the bar
        enabled: true,

        // Set the child, i.e. the application under the menu bar
        child: StartPage(
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
          title: title,
        ),
      );

  Widget home({required TranslationsBloc translationsBloc}) => BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          aboutAppMessage = translationsState.aboutAppMessage;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return translationsLoadingWindow(title: title);
        }

        if (Platform.isMacOS) {
          return menubar(context);
        }

        if (Platform.isWindows || Platform.isLinux) {
          return windowsLinuxMenuBar(
              context: context, translations: translations);
        }

        return StartPage(
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
          title: title,
        );
      });

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    if (kDebugMode == true) {
      debugPrint('build app');
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<TranslationsBloc>(
          create: (BuildContext context) => translationsBloc,
        ),
        BlocProvider<SettingsBloc>(
          create: (BuildContext context) => settingsBloc,
        ),
        BlocProvider<MainBloc>(
          create: (BuildContext context) => mainBloc,
        ),
      ],
      child: SharedWidgets.inMacosStyle()
          ? MacosApp(
              title: title,
              theme: MacosThemeData.light(isMainWindow: true),
              darkTheme: MacosThemeData.dark(isMainWindow: true),
              themeMode: ThemeMode.system,
              home: home(translationsBloc: translationsBloc),
            )
          : SharedWidgets.inIosStyle()
              ? Builder(builder: (context) {
                  brightnessValue = MediaQuery.of(context).platformBrightness;

                  if (kDebugMode) {
                    debugPrint('brightness: $brightnessValue');
                  }

                  return CupertinoApp(
                    title: title,
                    theme: CupertinoThemeData(
                      brightness: SharedWidgets.brightness(),
                      //primaryColor: CupertinoColors.systemBlue,
                    ),
                    home: home(translationsBloc: translationsBloc),
                  );
                })
              : MaterialApp(
                  title: title,
                  theme: materialThemeData(tabBarTheme: tabBarTheme),
                  darkTheme: ThemeData.dark(useMaterial3: false),
                  themeMode: ThemeMode.system,
                  home: home(translationsBloc: translationsBloc),
                ),
    );
  }
}
