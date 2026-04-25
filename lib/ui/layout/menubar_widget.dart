import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/mini_player_page.dart';
import 'package:roonmatrix/ui/helper/text_editing_service.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:window_manager/window_manager.dart';

class MenubarWidget extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final GlobalKey<NavigatorState> navigatorKey;
  final Function(BuildContext context) exportDeviceList;
  final Widget child;

  const MenubarWidget({
    super.key,
    required this.standardDesktopSize,
    required this.minDesktopSize,
    required this.navigatorKey,
    required this.exportDeviceList,
    required this.child,
  });

  @override
  State<MenubarWidget> createState() => MenubarWidgetState();
}

class MenubarWidgetState extends State<MenubarWidget> {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;
  Function(BuildContext context) get exportDeviceList =>
      widget.exportDeviceList;
  Widget get child => widget.child;

  Map<String, dynamic> translations = {};
  Map<String, dynamic> info = {};
  String selectedDeviceIp = '';
  String selectedDeviceIpBefore = '';
  String aboutAppMessage = '';
  bool isMatrixDevice = false;
  bool deviceSelectedAndReady = false;
  bool saveIdle = false;
  bool translationsLoaded = false;

  EditableTextState? lastFocusedEditable;

  void listenerFunction() {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;

    final editable = context?.findAncestorStateOfType<EditableTextState>();
    if (editable != null) {
      lastFocusedEditable = editable;
    }
  }

  late StreamSubscription mainStreamSubscription;
  late TranslationsBloc translationsBloc;
  late SettingsBloc settingsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    FocusManager.instance.addListener(listenerFunction);
    TextEditingService.instance.init();

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);

    mainStreamSubscription = mainBloc.stream.listen((MainState mainState) {
      if (mainState is MainStateLoaded) {
        if (selectedDeviceIpBefore != mainState.selectedDeviceIp) {
          selectedDeviceIp = mainState.selectedDeviceIp;
          info = mainState.info;
          selectedDeviceIpBefore = selectedDeviceIp;

          updateFlutterMenuBar(selectedDeviceIp: selectedDeviceIp, info: info);
        }
      }
    });

    super.initState();
  }

  Future<void> updateFlutterMenuBar({
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
  }) async {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        setState(() {
          deviceSelectedAndReady =
              selectedDeviceIp.isNotEmpty && info[selectedDeviceIp] != null;
          isMatrixDevice =
              (!(info[selectedDeviceIp] as Map<String, dynamic>).containsKey(
                'display_cover',
              ) ||
              info[selectedDeviceIp]['display_cover'] == false);
        });
      }
    });
  }

  MenuBarWidget windowsLinuxMenuBar({
    required BuildContext context,
    required Map<String, dynamic> translations,
    required Widget child,
  }) => MenuBarWidget(
    // Add a list of [BarButton]. The buttons in this List are
    // displayed as the buttons on the bar itself
    barButtons: windowsLinuxMenuBarButtons(
      context: context,
      translations: translations,
    ),

    // Style the menu bar itself. Hover over [MenuStyle] for all the options
    barStyle: MenuStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      backgroundColor: WidgetStatePropertyAll(
        Color(
          Globals.brightness() == Brightness.dark ? 0xFF2b2b2b : 0XFFF1F5F7,
        ),
      ),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
    ),

    // Style the menu bar buttons. Hover over [ButtonStyle] for all the options
    barButtonStyle: const ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6.0)),
      minimumSize: WidgetStatePropertyAll(Size(0.0, 32.0)),
    ),

    // Style the menu and submenu buttons. Hover over [ButtonStyle] for all the options
    menuButtonStyle: const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(36.0)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      ),
    ),

    // Enable or disable the bar
    enabled: true,

    // Set the child, i.e. the application under the menu bar
    child: child,
  );

  List<BarButton> windowsLinuxMenuBarButtons({
    required BuildContext context,
    required Map<String, dynamic> translations,
  }) {
    final editingService = TextEditingService.instance;

    return [
      BarButton(
        text: Text(
          translations['menuEntryFile'] ?? 'File',
          style: TextStyle(color: ColorDefs.textColor(context: context)),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () async => exportDeviceList(context),
              shortcutText: 'Ctrl+E',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyE,
                control: true,
              ),
              text: Text(
                translations['menuEntryExportDeviceList'] ??
                    'Export Device List',
              ),
              icon: const Icon(Icons.download),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () => showGeneralDialog(
                context: context,
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
              ),
              shortcutText: 'Ctrl+,',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                control: true,
              ),
              text: Text(translations['menuEntryWinSettings'] ?? 'Preferences'),
              icon: const Icon(Icons.settings),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () {
                SharedWidgets.showPlatformSpecificDialog(
                  context: context,
                  child: (BuildContext context) => AlertElement(
                    title:
                        translations['dialogQuitQuestion'] ??
                        'Do you really want to quit?',
                    button1Label: translations['dialogYes'] ?? 'Yes',
                    onPressed1: () => FlutterWindowClose.closeWindow(),
                    button2Label: translations['dialogNo'] ?? 'No',
                    onPressed2: () => Navigator.of(context).pop(false),
                  ),
                );
              },
              shortcut: const SingleActivator(LogicalKeyboardKey.f4, alt: true),
              shortcutText: 'ALT+F4',
              text: Text(translations['menuEntryWinQuit'] ?? 'Exit'),
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
      ),
      BarButton(
        text: Text(
          translations['menuEntryEdit'] ?? 'Edit',
          style: TextStyle(color: ColorDefs.textColor(context: context)),
        ),
        submenu: SubMenu(
          menuItems: [
            // MenuButton(
            //   onTap: () {
            //     editingService.undo();
            //   },
            //   icon: const Icon(Icons.undo),
            //   shortcut: const SingleActivator(
            //     LogicalKeyboardKey.keyZ,
            //     control: true,
            //   ),
            //   shortcutText: 'Ctrl+Z',
            //   text: Text(translations['menuEntryUndo'] ?? 'Undo'),
            // ),
            // MenuButton(
            //   onTap: () {
            //     editingService.undo();
            //   },
            //   icon: const Icon(Icons.undo),
            //   shortcut: const SingleActivator(
            //     LogicalKeyboardKey.keyZ,
            //     control: true,
            //     shift: true,
            //   ),
            //   shortcutText: 'Ctrl+Shift+Z',
            //   text: Text(translations['menuEntryUndo'] ?? 'Redo'),
            // ),
            // const MenuDivider(),
            MenuButton(
              onTap: () {
                editingService.cut();
              },
              icon: const Icon(Icons.cut),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyX,
                control: true,
              ),
              shortcutText: 'Ctrl+X',
              text: Text(translations['menuEntryCut'] ?? 'Cut'),
            ),
            MenuButton(
              onTap: () {
                editingService.copy();
              },
              icon: const Icon(Icons.copy),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyC,
                control: true,
              ),
              shortcutText: 'Ctrl+C',
              text: Text(translations['menuEntryCopy'] ?? 'Copy'),
            ),
            MenuButton(
              onTap: () {
                editingService.paste();
              },
              icon: const Icon(Icons.paste),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyV,
                control: true,
              ),
              shortcutText: 'Ctrl+V',
              text: Text(translations['menuEntryPaste'] ?? 'Paste'),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () {
                editingService.selectAll();
              },
              icon: const Icon(Icons.select_all),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyA,
                control: true,
              ),
              shortcutText: 'Ctrl+A',
              text: Text(translations['menuEntrySelectAll'] ?? 'Select all'),
            ),
          ],
        ),
      ),
      BarButton(
        text: Text(
          translations['menuEntryView'] ?? 'View',
          style: TextStyle(color: ColorDefs.textColor(context: context)),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () {
                if (navigatorKey.currentState != null &&
                    navigatorKey.currentState!.canPop()) {
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.home),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyB,
                control: true,
              ),
              shortcutText: 'Ctrl+B',
              text: Text(
                translations['backToMainViewLabel'] ?? 'Back to main page',
              ),
            ),
            MenuButton(
              onTap: () => mainBloc.selectDeviceBefore(ip: selectedDeviceIp),
              icon: const Icon(Icons.keyboard_arrow_up),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyB,
                control: true,
                alt: true,
              ),
              shortcutText: 'Ctrl+Alt+B',
              text: Text(
                translations['selectDeviceBeforeLabel'] ??
                    'Select previous device',
              ),
            ),
            MenuButton(
              onTap: () => mainBloc.selectDeviceNext(ip: selectedDeviceIp),
              icon: const Icon(Icons.keyboard_arrow_down),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                control: true,
                alt: true,
              ),
              shortcutText: 'Ctrl+Alt+N',
              text: Text(
                translations['selectDeviceNextLabel'] ?? 'Select next device',
              ),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () => mainBloc.windowResizeToFullWidthAndMinimumHeight(
                minDesktopSize: minDesktopSize,
              ),
              icon: const Icon(Icons.width_full),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyW,
                meta: true,
                control: true,
              ),
              shortcutText: 'Meta+Ctrl+W',
              text: Text(
                translations['fullWidthResizeButtonLabel'] ?? 'Full width',
              ),
            ),
            MenuButton(
              onTap: () => windowManager.setSize(
                Size(Globals.minDesktopWidth, Globals.minDesktopHeight + 24),
                animate: true,
              ),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: const Icon(Icons.photo_size_select_small),
              ),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyB,
                meta: true,
                control: true,
              ),
              shortcutText: 'Meta+Ctrl+B',
              text: Text(
                translations['minimizeResizeButtonLabel'] ?? 'Minimize',
              ),
            ),
            MenuButton(
              onTap: () =>
                  windowManager.setSize(standardDesktopSize, animate: true),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: const Icon(Icons.photo_size_select_large),
              ),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                meta: true,
                control: true,
              ),
              shortcutText: 'Ctrl+Equal',
              text: Text(
                translations['mediumResizeButtonLabel'] ?? 'Medium size',
              ),
            ),
            MenuButton(
              onTap: () => windowManager.maximize(),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: const Icon(Icons.photo_size_select_actual_outlined),
              ),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyM,
                meta: true,
                control: true,
              ),
              shortcutText: 'Ctrl+Plus',
              text: Text(
                translations['maximizeResizeButtonLabel'] ?? 'Maximize',
              ),
            ),
            const MenuDivider(),
            if (deviceSelectedAndReady) ...[
              MenuButton(
                onTap: () => SharedWidgets.openPage(
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
                icon: const Icon(Icons.handyman_outlined),
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  control: true,
                  shift: true,
                ),
                shortcutText: 'Ctrl+Shift+S',
                text: Text(translations['configButtonText'] ?? 'Config'),
              ),
              MenuButton(
                onTap: () => SharedWidgets.openPage(
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
                icon: const Icon(Icons.control_camera),
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyC,
                  control: true,
                  shift: true,
                ),
                shortcutText: 'Ctrl+Shift+C',
                text: Text(translations['controlButtonText'] ?? 'Control'),
              ),
              if (isMatrixDevice)
                MenuButton(
                  onTap: () => SharedWidgets.openPage(
                    context: context,
                    navigatorKey: navigatorKey,
                    page: MessagePage(
                      name: info[selectedDeviceIp]['name'],
                      ip: selectedDeviceIp,
                      minDesktopSize: minDesktopSize,
                      standardDesktopSize: standardDesktopSize,
                    ),
                  ),
                  icon: const Icon(Icons.message_outlined),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyM,
                    control: true,
                    shift: true,
                  ),
                  shortcutText: 'Ctrl+Shift+M',
                  text: Text(translations['messageButtonText'] ?? 'Message'),
                ),
              if (isMatrixDevice)
                MenuButton(
                  onTap: () => SharedWidgets.openPage(
                    context: context,
                    navigatorKey: navigatorKey,
                    page: LiveControlPage(
                      name: info[selectedDeviceIp]['name'],
                      ip: selectedDeviceIp,
                      minDesktopSize: minDesktopSize,
                      standardDesktopSize: standardDesktopSize,
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyL,
                    control: true,
                    shift: true,
                  ),
                  shortcutText: 'Ctrl+Shift+L',
                  text: Text(
                    translations['liveControlButtonText'] ?? 'Live Control',
                  ),
                ),
              MenuButton(
                onTap: () => SharedWidgets.openPage(
                  context: context,
                  navigatorKey: navigatorKey,
                  page: InfoPage(
                    name: info[selectedDeviceIp]['name'],
                    ip: selectedDeviceIp,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                  ),
                ),
                icon: const Icon(Icons.monitor),
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyI,
                  control: true,
                  shift: true,
                ),
                shortcutText: 'Ctrl+Shift+I',
                text: Text(translations['infoButtonText'] ?? 'Monitoring'),
              ),
              MenuButton(
                onTap: () => SharedWidgets.openPage(
                  context: context,
                  navigatorKey: navigatorKey,
                  page: LogPage(
                    name: info[selectedDeviceIp]['name'],
                    ip: selectedDeviceIp,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                  ),
                ),
                icon: const Icon(Icons.terminal),
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyD,
                  control: true,
                  shift: true,
                ),
                shortcutText: 'Ctrl+Shift+D',
                text: Text(translations['logButtonText'] ?? 'Log'),
              ),
              MenuButton(
                onTap: () {
                  bool miniPlayerAlwaysOnTop =
                      settingsBloc.state.miniPlayerAlwaysOnTop;
                  bool miniPlayerPreventCloseApp =
                      settingsBloc.state.miniPlayerPreventCloseApp;
                  bool miniPlayerShowTextInfoOnTrackChange =
                      settingsBloc.state.miniPlayerShowTextInfoOnTrackChange;
                  int miniPlayerTextInfoDuration =
                      settingsBloc.state.miniPlayerTextInfoDuration;

                  Map<String, dynamic> i = info[selectedDeviceIp];
                  String controlId = i['control_id'];
                  String zoneName = '-';
                  if (i['channels'] != null &&
                      i['channels'][controlId] != null) {
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
                // icon: const Icon(Icons.play_arrow),
                icon: SvgPicture.asset(
                  'assets/svg/albumcover.svg',
                  allowDrawingOutsideViewBox: false,
                  fit: BoxFit.contain,
                  width: 24.0,
                  alignment: Alignment.center,
                ),
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyP,
                  control: true,
                  shift: true,
                ),
                shortcutText: 'Ctrl+Shift+P',
                text: Text(
                  translations['miniPlayerPageHeaderText'] ?? 'Mini Player',
                ),
              ),
            ],
          ],
        ),
      ),
      BarButton(
        text: Text(
          translations['menuEntryHelp'] ?? 'Help',
          style: TextStyle(color: ColorDefs.textColor(context: context)),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () => SharedWidgets.openAboutModal(
                context: context,
                aboutAppMessage: aboutAppMessage,
                translations: translations,
              ),
              icon: const Icon(Icons.info),
              text: Text(
                translations['menuEntryAbout'] ??
                    'About ${Globals.mainWindowTitle}',
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          aboutAppMessage = translationsState.aboutAppMessage;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return SizedBox();
        }

        return windowsLinuxMenuBar(
          context: context,
          translations: translations,
          child: child,
        );
      },
    );
  }

  @override
  Future<void> dispose() async {
    mainStreamSubscription.cancel();
    FocusManager.instance.removeListener(listenerFunction);

    super.dispose();
  }
}
