import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mac_menu_bar/mac_menu_bar.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/mini_player_page.dart';
import 'package:roonmatrix/ui/helper/text_editing_service.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:window_manager/window_manager.dart';

class MenubarMacos extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final GlobalKey<NavigatorState> navigatorKey;

  const MenubarMacos({
    super.key,
    required this.standardDesktopSize,
    required this.minDesktopSize,
    required this.navigatorKey,
  });

  @override
  State<MenubarMacos> createState() => MenubarMacosState();
}

class MenubarMacosState extends State<MenubarMacos> {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;

  Map<String, dynamic> translations = {};
  Map<String, dynamic> info = {};
  String selectedDeviceIp = '';
  String selectedDeviceIpBefore = '';
  bool saveIdle = false;
  bool translationsLoaded = false;
  bool macMenuInitialized = false;

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

  void openPage({required BuildContext context, required Widget page}) {
    navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => route.isFirst); // close all pages except main page
    // navigatorKey.currentState!.push(
    //   MaterialPageRoute(builder: (_) => page),
    // );
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
            failMessage:
                translations['exportFailedMessage'] ?? 'Export failed!',
            valid: valid);
      }
    });
  }

  Future<void> addMacMenuDeviceNavigation() async {
    // Add items to the View menu

    // await MacMenuBar.addMenuItem(
    //   menuId: 'View',
    //   itemId: 'close_page',
    //   title: translations['closePageLabel'] ?? 'Close page',
    //   shortcut: const SingleActivator(
    //     LogicalKeyboardKey.arrowLeft,
    //     control: true,
    //     shift: true,
    //     alt: false,
    //   ),
    // );

    await MacMenuBar.addMenuItem(
      menuId: 'View',
      itemId: 'back_to_main',
      title: translations['backToMainViewLabel'] ?? 'Back to main page',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.arrowLeft,
        control: true,
        shift: true,
        alt: false,
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
    final editingService = TextEditingService.instance;

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

    MacMenuBar.onCut(() async {
      editingService.cut();
      return true; // Return true to indicate the action was handled
    });

    // Handle Copy menu item
    MacMenuBar.onCopy(() async {
      editingService.copy();
      return true;
    });

    // Handle Paste menu item
    MacMenuBar.onPaste(() async {
      editingService.paste();
      return true;
    });

    // Handle Select All menu item
    MacMenuBar.onSelectAll(() async {
      editingService.selectAll();
      return true;
    });

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
      // case 'close_page':
      //   if (navigatorKey.currentState != null &&
      //       navigatorKey.currentState!.canPop()) {
      //     navigatorKey.currentState?.pop();
      //   }
      //   break;
      case 'back_to_main':
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
            return SizedBox();
          }

          setupMacMenuStructure(context: context, translations: translations);

          return SizedBox();
        });
  }

  @override
  Future<void> dispose() async {
    mainStreamSubscription.cancel();
    FocusManager.instance.removeListener(listenerFunction);

    super.dispose();
  }
}
