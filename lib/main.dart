import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:enhanced_platform_menu/enhanced_platform_menu_delegate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/connection_status_bloc.dart';
import 'package:roonmatrix/ui/helper/connection_status_state.dart';
import 'package:roonmatrix/ui/layout/menubar_apple_extended_class.dart';
import 'package:roonmatrix/ui/layout/menubar_apple_custom_class.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/main_shell.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:window_manager/window_manager.dart';

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
  final bool useCustomMacMenu = false;

  WidgetsFlutterBinding.ensureInitialized();
  if (!useCustomMacMenu) {
    WidgetsBinding.instance.platformMenuDelegate =
        EnhancedPlatformMenuDelegate();
  }

  if (Globals.inMacosStyle()) {
    await _configureMacosWindowUtils();
  }

  runApp(
    RoonMatrix(
      minDesktopSize: Globals.minDesktopSize,
      standardDesktopSize: Globals.standardDesktopSize,
      useCustomMacMenu: useCustomMacMenu,
    ),
  );

  Bloc.transformer =
      sequential<
        dynamic
      >(); // all bloc events strictly sequential (like mapEventToState in bloc prior v8)

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
  final bool useCustomMacMenu;

  const RoonMatrix({
    super.key,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.useCustomMacMenu,
  });

  @override
  State<RoonMatrix> createState() => RoonMatrixState();
}

class RoonMatrixState extends State<RoonMatrix> {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  bool get useCustomMacMenu => widget.useCustomMacMenu;

  final FileRepository fileRepository = FileRepository();
  final String title = Globals.mainWindowTitle;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  Map<String, dynamic> translations = {};
  Map<String, dynamic> info = {};
  String selectedDeviceIp = '';
  String aboutAppMessage = '';
  bool translationsLoaded = false;
  bool saveIdle = false;
  bool macMenuInitialized = false;

  EditableTextState? lastFocusedEditable;
  Brightness? brightnessValue;
  MenubarAppleExtendedClass? menubarAppleExtendedClass;
  MenubarAppleCustomClass? menubarAppleCustomClass;
  Widget? mainPageWithMenuForApple;
  String? selectedDeviceIpBefore;

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

    super.initState();
  }

  TabBarThemeData tabBarThemeData = const TabBarThemeData(
    labelColor: Colors.white,
    dividerColor: Colors.grey,
    labelStyle: TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(width: 2, color: Colors.red),
    ),
  );

  ThemeData materialThemeData({required TabBarThemeData tabBarThemeData}) =>
      ThemeData(useMaterial3: false, tabBarTheme: tabBarThemeData);

  Widget translationsLoadingWindow({required String title}) {
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
                  return Material(child: MacosWindow(child: SizedBox()));
                }),
              ),
            ],
          )
        : Scaffold(
            appBar: AppBar(title: Text(title), actions: const []),
            body: const SizedBox(),
          );
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

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        SharedWidgets.showSnackBar(
          context: context,
          doneMessage:
              translations['exportDoneMessage'] ?? 'Export successfully done',
          failMessage: translations['exportFailedMessage'] ?? 'Export failed!',
          valid: valid,
        );
      }
    });
  }

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

      if (Platform.isMacOS || Platform.isIOS) {
        if (useCustomMacMenu == true && Platform.isMacOS) {
          menubarAppleCustomClass = MenubarAppleCustomClass(
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
            navigatorKey: navigatorKey,
            translations: translations,
            aboutAppMessage: aboutAppMessage,
            mainBloc: mainBloc,
            settingsBloc: settingsBloc,
            exportDeviceList: exportDeviceList,
          );
          menubarAppleCustomClass!.init();
        } else {
          menubarAppleExtendedClass = MenubarAppleExtendedClass(
            minDesktopSize: minDesktopSize,
            standardDesktopSize: standardDesktopSize,
            navigatorKey: navigatorKey,
            translations: translations,
            aboutAppMessage: aboutAppMessage,
            mainBloc: mainBloc,
            settingsBloc: settingsBloc,
            exportDeviceList: exportDeviceList,
          );
          menubarAppleExtendedClass!.init();
        }

        return BlocBuilder(
          bloc: mainBloc,
          builder: (context, MainState mainState) {
            if (mainState is MainStateLoaded) {
              if (selectedDeviceIpBefore != mainState.selectedDeviceIp) {
                selectedDeviceIp = mainState.selectedDeviceIp;
                info = mainState.info;
                selectedDeviceIpBefore = selectedDeviceIp;
                Map<String, dynamic> spotifyAuthUrls =
                    mainState.spotifyAuthUrls;
                bool isIPad = mainState.isIPad;
                int iosMajorVersion = mainState.iosMajorVersion;

                if (useCustomMacMenu == true && Platform.isMacOS) {
                  mainPageWithMenuForApple = menubarAppleCustomClass!
                      .macosMenubar(
                        context: context,
                        selectedDeviceIp: selectedDeviceIp,
                        info: info,
                        spotifyAuthUrls: spotifyAuthUrls,
                        child: MainShell(
                          minDesktopSize: minDesktopSize,
                          standardDesktopSize: standardDesktopSize,
                          title: title,
                          navigatorKey: navigatorKey,
                          exportDeviceList: exportDeviceList,
                        ),
                      );
                } else {
                  if (Platform.isMacOS ||
                      (Platform.isIOS &&
                          isIPad == true &&
                          iosMajorVersion >= 15)) {
                    mainPageWithMenuForApple = menubarAppleExtendedClass!
                        .appleMenubar(
                          context: context,
                          isIPad: isIPad,
                          selectedDeviceIp: selectedDeviceIp,
                          info: info,
                          spotifyAuthUrls: spotifyAuthUrls,
                          child: MainShell(
                            minDesktopSize: minDesktopSize,
                            standardDesktopSize: standardDesktopSize,
                            title: title,
                            navigatorKey: navigatorKey,
                            exportDeviceList: exportDeviceList,
                          ),
                        );
                  }
                }
              }
            }

            return mainPageWithMenuForApple ??
                MainShell(
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                  title: title,
                  navigatorKey: navigatorKey,
                  exportDeviceList: exportDeviceList,
                );
          },
        );
      }

      return MainShell(
        minDesktopSize: minDesktopSize,
        standardDesktopSize: standardDesktopSize,
        title: title,
        navigatorKey: navigatorKey,
        exportDeviceList: exportDeviceList,
      );
    },
  );

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
          BlocProvider<MainBloc>(create: (BuildContext context) => mainBloc),
        ],
        child: Globals.inMacosStyle()
            ? MacosApp(
                title: title,
                theme: MacosThemeData.light(isMainWindow: true),
                darkTheme: MacosThemeData.dark(isMainWindow: true),
                themeMode: ThemeMode.system,
                localizationsDelegates: [DefaultMaterialLocalizations.delegate],
                // navigatorKey: navigatorKey,
                home: home(translationsBloc: translationsBloc),
              )
            : Globals.inIosStyle()
            ? Builder(
                builder: (context) {
                  brightnessValue = MediaQuery.of(context).platformBrightness;

                  return CupertinoApp(
                    title: title,
                    theme: CupertinoThemeData(
                      brightness: Globals.brightness(),
                      //primaryColor: CupertinoColors.systemBlue,
                    ),
                    localizationsDelegates: [
                      DefaultMaterialLocalizations.delegate,
                    ],
                    // navigatorKey: navigatorKey,
                    home: home(translationsBloc: translationsBloc),
                  );
                },
              )
            : MaterialApp(
                title: title,
                theme: materialThemeData(tabBarThemeData: tabBarThemeData),
                darkTheme: ThemeData.dark(useMaterial3: false),
                themeMode: ThemeMode.system,
                // navigatorKey: navigatorKey,
                home: home(translationsBloc: translationsBloc),
              ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    menubarAppleExtendedClass?.dispose();
    menubarAppleCustomClass?.dispose();
    connectionStatusStreamSubscription.cancel();

    super.dispose();
  }
}
