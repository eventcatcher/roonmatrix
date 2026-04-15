import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/mini_player_page.dart';
import 'package:roonmatrix/ui/helper/connection_status_bloc.dart';
import 'package:roonmatrix/ui/helper/connection_status_state.dart';
import 'package:roonmatrix/ui/layout/menubar_widget.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:window_manager/window_manager.dart';
import 'package:mac_menu_bar/mac_menu_bar.dart';

Future<void> _configureMacosWindowUtils() async {
  const MacosWindowUtilsConfig config = MacosWindowUtilsConfig(
    makeTitlebarTransparent: true,
    toolbarStyle: NSWindowToolbarStyle.automatic,
  );

  final String macosVersion = await Globals.getMacosVersion();
  final int macosVersionMajor = int.parse(macosVersion.split('.').first);
  if (macosVersionMajor >= 13) {
    await config.apply(); // crashing on older macs with macos version < 13.0
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Globals.inMacosStyle()) {
    await _configureMacosWindowUtils();
  }

  runApp(RoonMatrix(
    minDesktopSize: Globals.minDesktopSize,
    standardDesktopSize: Globals.standardDesktopSize,
  ));

  Bloc.transformer = sequential<
      dynamic>(); // all bloc events strictly sequential (like mapEventToState in bloc prior v8)

  if (Globals.isDesktopDevice()) {
    doWhenWindowReady(() {
      appWindow.minSize = Globals.minDesktopSize;
      appWindow.size = Globals.standardDesktopSize;

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
  final String title = Globals.mainWindowTitle;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;
  bool saveIdle = false;
  bool macMenuInitialized = false;
  EditableTextState? lastFocusedEditable;
  String selectedDeviceIp = '';
  String selectedDeviceIpBefore = '';
  Map<String, dynamic> info = {};

  Brightness? brightnessValue;

  late StreamSubscription mainStreamSubscription;
  late StreamSubscription connectionStatusStreamSubscription;
  late TranslationsBloc translationsBloc;
  late SettingsBloc settingsBloc;
  late ConnectionStatusBloc connectionStatusBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    fileRepository.init();

    initializeDateFormatting('de_DE', null);

    translationsBloc = TranslationsBloc(fileRepository: fileRepository);
    settingsBloc = SettingsBloc();
    connectionStatusBloc = ConnectionStatusBloc();
    connectionStatusBloc.init();
    mainBloc = MainBloc(fileRepository: fileRepository);
    mainBloc.loadDefaults();

    connectionStatusStreamSubscription = connectionStatusBloc.stream.listen((
      ConnectionStatusState connectionStatusState,
    ) {
      if (connectionStatusState is ConnectionStatusStateLoaded &&
          connectionStatusState.connected) {
        if (Globals.isMobileDevice() == true) {
          mainBloc.resetWebSocketServices();
        }

        WidgetsBinding.instance.addPostFrameCallback((timestamp) {
          mainBloc.restartPollingTimer();
          mainBloc.searching(idle: Globals.isMobileDevice());
        });
      }
    });

    mainStreamSubscription = mainBloc.stream.listen((
      MainState mainState,
    ) {
      if (mainState is MainStateLoaded) {
        if (selectedDeviceIpBefore != mainState.selectedDeviceIp) {
          selectedDeviceIp = mainState.selectedDeviceIp;
          info = mainState.info;
          selectedDeviceIpBefore = selectedDeviceIp;
          updateMacMenuBar(selectedDeviceIp: selectedDeviceIp, info: info);
        }
      }
    });

    super.initState();
  }

  Future<void> addMacMenuDeviceNavigation() async {
    // Add items to the View menu

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'close_page',
      title: translations['closePageLabel'] ?? 'Close page',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.arrowLeft,
        control: true,
        shift: true,
        alt: false,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'back_to_main',
      title: translations['backToMainViewLabel'] ?? 'Back to main page',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.arrowLeft,
        control: true,
        shift: true,
        alt: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'device_before',
      title:
          translations['selectDeviceBeforeLabel'] ?? 'Select previous device',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.arrowUp,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'device_next',
      title: translations['selectDeviceNextLabel'] ?? 'Select next device',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.arrowDown,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'resize_minimize',
      title: translations['minimizeResizeButtonLabel'] ?? 'Minimize',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.minus,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'resize_full_width',
      title: translations['fullWidthResizeButtonLabel'] ?? 'Full width',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyW,
        control: true,
        shift: true,
      ),
    );
  }

  Future<void> addMacMenuPageItemsFirstPart() async {
    // Add items to the View menu
    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'config_page',
      title: translations['configButtonText'] ?? 'Config',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyS,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'control_page',
      title: translations['controlButtonText'] ?? 'Control',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyC,
        control: true,
        shift: true,
      ),
    );
  }

  Future<void> addMacMenuPageItemsMatrixOnlyPart() async {
    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'message_page',
      title: translations['messageButtonText'] ?? 'Message',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyM,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'live_control_page',
      title: translations['liveControlButtonText'] ?? 'Live Control',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyL,
        control: true,
        shift: true,
      ),
    );
  }

  Future<void> addMacMenuPageItemsLastPart() async {
    // Add items to the View menu
    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'monitoring_page',
      title: translations['infoButtonText'] ?? 'Monitoring',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyI,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'log_page',
      title: translations['logButtonText'] ?? 'Log',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyD,
        control: true,
        shift: true,
      ),
    );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'miniplayer_page',
      title: translations['miniPlayerPageHeaderText'] ?? 'Mini Player',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyP,
        control: true,
        shift: true,
      ),
    );
  }

  Future<void> updateMacMenuBar({
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
  }) async {
    await MacMenuBar.removeMenuItem('config_page');
    await MacMenuBar.removeMenuItem('control_page');
    await MacMenuBar.removeMenuItem('message_page');
    await MacMenuBar.removeMenuItem('live_control_page');
    await MacMenuBar.removeMenuItem('monitoring_page');
    await MacMenuBar.removeMenuItem('log_page');
    await MacMenuBar.removeMenuItem('miniplayer_page');

    if (selectedDeviceIp.isNotEmpty && info[selectedDeviceIp] != null) {
      await addMacMenuPageItemsFirstPart();

      if (!(info[selectedDeviceIp] as Map<String, dynamic>)
              .containsKey('display_cover') ||
          info[selectedDeviceIp]['display_cover'] == false) {
        await addMacMenuPageItemsMatrixOnlyPart();
      }

      await addMacMenuPageItemsLastPart();
    }
  }

  Future<void> setupMacMenuStructure({
    required BuildContext context,
    required Map<String, dynamic> translations,
  }) async {
    if (macMenuInitialized == true) {
      return;
    }

    MacMenuBar.onSettings(() async {
      showGeneralDialog(
        context: context,
        // barrierColor:
        //     Colors.black12.withOpacity(0.6), // Background color
        barrierDismissible: false,
        barrierLabel: 'Dialog',
        transitionDuration: const Duration(milliseconds: 0),
        pageBuilder: (_, __, ___) {
          return SettingsPage(
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          );
        },
      );
      return true;
    });

    // MacMenuBar.onCut(() async {
    //   debugPrint('Cut menu item selected');
    //   // Implement your cut logic here
    //   return true; // Return true to indicate the action was handled
    // });

    // // Handle Copy menu item
    // MacMenuBar.onCopy(() async {
    //   debugPrint('Copy menu item selected');
    //   // Implement your copy logic here
    //   return true;
    // });

    // // Handle Paste menu item
    // MacMenuBar.onPaste(() async {
    //   debugPrint('Paste menu item selected');
    //   // Implement your paste logic here
    //   return true;
    // });

    // // Handle Select All menu item
    // MacMenuBar.onSelectAll(() async {
    //   debugPrint('Select All menu item selected');
    //   // Implement your select all logic here
    //   return true;
    // });

    await MacMenuBar.addMenuItem(
      menuId: 'main',
      itemId: 'test',
      title: translations['menuEntrySettings'] ?? 'Settings',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.comma,
        meta: true,
        shift: true,
      ), // Cmd+,
    );

    await MacMenuBar.addSubmenu(
      parentMenuId: 'main',
      submenuId: 'file_menu',
      title: 'File',
      index: 1,
    );

    // Add items to the File menu
    await MacMenuBar.addMenuItem(
      menuId: 'file_menu',
      itemId: 'export',
      title: translations['menuEntryExportDeviceList'] ?? 'Export Device List',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyE,
        control: true,
        shift: false,
      ), // Cmd+Shift+E
    );

    addMacMenuDeviceNavigation();

    MacMenuBar.setMenuItemSelectedHandler((itemId) {
      handleMacCustomMenuItem(context: context, itemId: itemId);
    });

    macMenuInitialized = true;
  }

  void openPage({required BuildContext context, required Widget page}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dialog',
      transitionDuration: const Duration(milliseconds: 0),
      pageBuilder: (_, __, ___) {
        return page;
      },
    );
  }

  void handleMacCustomMenuItem({
    required BuildContext context,
    required String itemId,
  }) {
    switch (itemId) {
      case 'export':
        exportDeviceList(context);
        break;
      case 'config_page':
        openPage(
          context: context,
          page: ConfigPage(
            name: info[selectedDeviceIp]['name'],
            ip: selectedDeviceIp,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
            close: () {
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'control_page':
        openPage(
          context: context,
          page: CoverPage(
            name: info[selectedDeviceIp]['name'],
            ip: selectedDeviceIp,
            translations: translations,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        );
        break;
      case 'message_page':
        openPage(
          context: context,
          page: MessagePage(
            name: info[selectedDeviceIp]['name'],
            ip: selectedDeviceIp,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        );
        break;
      case 'live_control_page':
        openPage(
          context: context,
          page: LiveControlPage(
            name: info[selectedDeviceIp]['name'],
            ip: selectedDeviceIp,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        );
        break;
      case 'monitoring_page':
        openPage(
          context: context,
          page: InfoPage(
            name: info[selectedDeviceIp]['name'],
            ip: selectedDeviceIp,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        );
        break;
      case 'log_page':
        openPage(
          context: context,
          page: LogPage(
            name: info[selectedDeviceIp]['name'],
            ip: selectedDeviceIp,
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
          ),
        );
        break;
      case 'miniplayer_page':
        bool miniPlayerAlwaysOnTop = settingsBloc.state.miniPlayerAlwaysOnTop;
        bool miniPlayerPreventCloseApp =
            settingsBloc.state.miniPlayerPreventCloseApp;
        bool miniPlayerShowTextInfoOnTrackChange =
            settingsBloc.state.miniPlayerShowTextInfoOnTrackChange;
        int miniPlayerTextInfoDuration =
            settingsBloc.state.miniPlayerTextInfoDuration;

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

        openPage(
          context: context,
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
        break;
      case 'close_page':
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        break;
      case 'back_to_main':
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 'device_before':
        mainBloc.selectDeviceBefore(ip: selectedDeviceIp);
        break;
      case 'device_next':
        mainBloc.selectDeviceNext(ip: selectedDeviceIp);
        break;
      case 'resize_minimize':
        windowManager.setSize(standardDesktopSize, animate: true);
        break;
      case 'resize_full_width':
        mainBloc.windowResizeToFullWidthAndMinimumHeight(
            minDesktopSize: minDesktopSize);
        break;
      default:
        debugPrint('Unknown menu item: $itemId');
    }
  }

  TabBarThemeData tabBarThemeData = const TabBarThemeData(
      labelColor: Colors.white,
      dividerColor: Colors.grey,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2, color: Colors.red)));

  ThemeData materialThemeData({
    required TabBarThemeData tabBarThemeData,
  }) =>
      ThemeData(
        useMaterial3: false,
        tabBarTheme: tabBarThemeData,
      );

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

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        SharedWidgets.showSnackBar(
            context: context,
            doneMessage:
                translations['exportDoneMessage'] ?? 'Export successfully done',
            failMessage:
                translations['exportFailedMessage'] ?? 'Export failed!',
            valid: valid);
      }
    });
  }

  Widget translationsLoadingWindow({
    required String title,
  }) {
    if (Globals.inIosStyle()) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          brightness: Globals.brightness(),
          middle: Text(title),
        ),
        child: SizedBox(),
      );
    }

    return Globals.inMacosStyle()
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

  Widget home({
    required TranslationsBloc translationsBloc,
  }) =>
      BlocBuilder(
          bloc: translationsBloc,
          builder: (context, TranslationsState translationsState) {
            if (translationsState is TranslationsStateLoaded) {
              translations = translationsState.translations;
              translationsLoaded = translationsState.translationsLoaded;
            }

            if (translationsState is! TranslationsStateLoaded ||
                !translationsLoaded) {
              return translationsLoadingWindow(title: title);
            }

            if (Platform.isWindows || Platform.isLinux) {
              return MenubarWidget(
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
                child: StartPage(
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                  title: title,
                ),
              );
            }

            if (Platform.isMacOS) {
              setupMacMenuStructure(
                  context: context, translations: translations);
              return StartPage(
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
                title: title,
              );
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MainRepository>(
          create: (BuildContext context) => MainRepository(),
        ),
        RepositoryProvider<FileRepository>(
          create: (BuildContext context) => fileRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TranslationsBloc>(
            create: (BuildContext context) => translationsBloc,
          ),
          BlocProvider<SettingsBloc>(
            create: (BuildContext context) => settingsBloc,
          ),
          BlocProvider<ConnectionStatusBloc>(
            create: (BuildContext context) => connectionStatusBloc,
          ),
          BlocProvider<MainBloc>(
            create: (BuildContext context) => mainBloc,
          ),
        ],
        child: Globals.inMacosStyle()
            ? MacosApp(
                title: title,
                theme: MacosThemeData.light(isMainWindow: true),
                darkTheme: MacosThemeData.dark(isMainWindow: true),
                themeMode: ThemeMode.system,
                localizationsDelegates: [DefaultMaterialLocalizations.delegate],
                home: home(translationsBloc: translationsBloc),
              )
            : Globals.inIosStyle()
                ? Builder(builder: (context) {
                    brightnessValue = MediaQuery.of(context).platformBrightness;

                    return CupertinoApp(
                      title: title,
                      theme: CupertinoThemeData(
                        brightness: Globals.brightness(),
                        //primaryColor: CupertinoColors.systemBlue,
                      ),
                      localizationsDelegates: [
                        DefaultMaterialLocalizations.delegate
                      ],
                      home: home(translationsBloc: translationsBloc),
                    );
                  })
                : MaterialApp(
                    title: title,
                    theme: materialThemeData(tabBarThemeData: tabBarThemeData),
                    darkTheme: ThemeData.dark(useMaterial3: false),
                    themeMode: ThemeMode.system,
                    home: home(translationsBloc: translationsBloc),
                  ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    connectionStatusStreamSubscription.cancel();
    mainStreamSubscription.cancel();

    super.dispose();
  }
}
