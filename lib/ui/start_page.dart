import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/control_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/scroll_matrix_page.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/burger_menu.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

class StartPage extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final String title;

  const StartPage({
    super.key,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.title,
  });

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  String get title => widget.title;

  final double treeFontSize = 12;

  Map<String, dynamic> info = {};
  Map<String, dynamic> translations = {};
  List<String> devices = [];
  String aboutAppMessage = '';
  double width = 1280;
  double height = 768;
  bool translationsLoaded = false;
  bool idle = false;
  bool saveIdle = false;
  Display? primaryDisplay;

  late SettingsBloc settingsBloc;
  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late String appVersionAndBuildNumber;

  bool settingsPageLoaded = false;
  bool _isDrawerOpen = false;
  bool moreInfo = false;

  @override
  void initState() {
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    super.initState();
  }

  void openAboutModal(
          {required BuildContext context,
          required String aboutAppMessage,
          required Map<String, dynamic> translations}) =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          mainBloc.openAboutModal(
              context: context,
              aboutAppMessage: aboutAppMessage,
              translations: translations);
        }
      });

  void openSettingsPage() =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await showGeneralDialog(
            context: context,
            //barrierColor: Colors.black12.withOpacity(0.6), // Background color
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
        }
      });

  getFormattedDateString(
      {required String date,
      String languageCode = 'de',
      String format = 'dd.MM.yyyy hh:mm:ss'}) {
    String formattedDate =
        DateFormat(format, languageCode).format(DateTime.parse(date));

    return formattedDate;
  }

  updateSizes(String caller) {
    width = MediaQuery.of(context).size.height;
    height = MediaQuery.of(context).size.height;
    // if (kDebugMode) {
    //   print(
    //       'StartPage => updateSizes, caller: $caller, width: $width, height: $height');
    // }
  }

  openBurgerMenuItem(String? key) {
    if (key == 'about') {
      openAboutModal(
          context: context,
          aboutAppMessage: aboutAppMessage,
          translations: translations);
    }
    if (key == 'settings') {
      openSettingsPage();
    }
  }

  burgerMenuRaw(bool noPop) => BurgerMenu(
        translations: translations,
        noPop: noPop,
        onClose: (String? key) {
          setState(() => _isDrawerOpen = false);
          return openBurgerMenuItem(key);
        },
      );

  burgerMenu() => BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          aboutAppMessage = translationsState.aboutAppMessage;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return const SizedBox();
        }

        return SharedWidgets.inIosStyle()
            ? burgerMenuRaw(true)
            : Drawer(
                child: burgerMenuRaw(false),
              );
      });

  String replaceCodes(String str) {
    if (str.length > 1 && str.startsWith('[') && str.endsWith(']')) {
      str = jsonDecode(str.replaceAll("'", '"')).join(' ');
      str = str.replaceAll('< ', ', ');
      str = str.replaceAll(' >', ': ');
    }

    return str;
  }

  List<Widget> mobileButtons1(orientation, i, zoneName, index) => [
        if (orientation == Orientation.portrait)
          Text('${i['playcount']}',
              softWrap: true,
              overflow: TextOverflow.fade,
              style: const TextStyle(fontSize: 9)),
        if (orientation == Orientation.landscape)
          Text(
            '${translations['deviceListTime'] ?? 'time'}: ${getFormattedDateString(date: i['time'])}\n${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'zone'}: ${i['playcount']}  ',
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: const TextStyle(fontSize: 11),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
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
                    name: i['name'],
                    ip: devices[index],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return ControlPage(
                    ip: devices[index],
                    name: i['name'],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.control_camera,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
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
                    ip: devices[index],
                    name: i['name'],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.message_outlined,
                color: Colors.white,
                size: 19.0,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
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
                    ip: devices[index],
                    name: i['name'],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.visibility_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ];

  List<Widget> mobileButtons2(orientation, i, zoneName, index) => [
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
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
                      name: i['name'],
                      ip: devices[index],
                      close: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
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
                      name: i['name'],
                      ip: devices[index],
                      close: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                icon: const Icon(
                  Icons.terminal,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ];

  body() => BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return const SizedBox();
        }

        return BlocBuilder(
            bloc: settingsBloc,
            builder: (context, SettingsState settingsState) {
              if (settingsState is! SettingsStateLoaded) {
                return SizedBox();
              }

              moreInfo = settingsState.moreInfo;

              return BlocBuilder(
                  bloc: mainBloc,
                  builder: (context, MainState mainState) {
                    if (mainState is! MainStateLoaded) {
                      return SizedBox();
                    }

                    if ((mainState.ipStart == null ||
                            mainState.ipEnd == null) &&
                        !settingsPageLoaded) {
                      settingsPageLoaded = true;
                      openSettingsPage();
                    }

                    devices = mainState.devices;
                    info = mainState.info;
                    idle = mainState.idle;

                    if (mainState.searchFilter.isNotEmpty &&
                        devices.isNotEmpty) {
                      devices = devices
                          .where((String el) => (info[el]['name'] as String)
                              .toLowerCase()
                              .contains(
                                  (mainState.searchFilter['main'] as String)
                                      .toLowerCase()))
                          .toList();
                    }

                    // devices = [
                    //   // enable this to test with multiple fake-devices
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices
                    // ];

                    if (kDebugMode) {
                      print(
                          'state changed => rebuild, devices: ${devices.length}, idle: $idle');
                    }
                    return OrientationBuilder(builder:
                        (BuildContext context, Orientation orientation) {
                      return Container(
                        color: SharedWidgets.windowBackgroundColor(
                            context: context),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Stack(
                                children: [
                                  // searchfield area
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8.0, right: 8.0),
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      direction: Axis.horizontal,
                                      children: [
                                        SearchField(
                                          type: 'main',
                                          controller:
                                              mainBloc.getSearchController(
                                                  type: 'main'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (mainState.logMessage.isNotEmpty)
                                SizedBox(
                                  height: 300.0,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(
                                                SharedWidgets.inIosStyle()
                                                    ? 8
                                                    : 5)),
                                      ),
                                      color: Colors.lightBlueAccent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Text(
                                                translations['debugMessage'] ??
                                                    'Debug Messages:',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Expanded(
                                              child: ListView(
                                                children: [
                                                  Text(mainState.logMessage),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: idle == true
                                    ? LoadingIndicatorBig(
                                        message: translations['scanMessage'] ??
                                            'scan for devices')
                                    : devices.isEmpty
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 184,
                                                height: 184,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.deepOrange,
                                                    width: 5.0,
                                                  ),
                                                  borderRadius: BorderRadius
                                                      .all(Radius.circular(
                                                          SharedWidgets
                                                                  .inIosStyle()
                                                              ? 8
                                                              : 5)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.deepOrange
                                                          .withOpacity(0.15),
                                                      spreadRadius: 0,
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: Text(
                                                    translations[
                                                            'scanNoFoundMessage'] ??
                                                        'no devices found',
                                                    style: TextStyle(
                                                      color: SharedWidgets
                                                          .textColor(
                                                              context: context),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : ListView.separated(
                                            key: ValueKey(
                                                'deviceList${devices.length}'),
                                            separatorBuilder:
                                                (context, index) =>
                                                    const Divider(
                                                      color: Colors.white,
                                                      height: 1,
                                                    ),
                                            itemCount: devices.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              dynamic i = info[devices[index]];

                                              String zoneName = '';
                                              if (i['control_id'] != null) {
                                                String controlId =
                                                    i['control_id'];
                                                if (i['channels'] != null &&
                                                    i['channels'][controlId] !=
                                                        null) {
                                                  if (i['channels']
                                                          [controlId] ==
                                                      'webserver') {
                                                    zoneName = controlId;
                                                  } else {
                                                    zoneName = i['channels']
                                                        [controlId];
                                                  }
                                                }
                                              }

                                              return Container(
                                                color: SharedWidgets
                                                    .tileBackgroundColor(
                                                        context: context),
                                                height: Platform.isAndroid &&
                                                        orientation ==
                                                            Orientation
                                                                .portrait &&
                                                        moreInfo == true
                                                    ? 100
                                                    : 83.0,
                                                child: Stack(
                                                  children: [
                                                    ListTile(
                                                      minLeadingWidth: 28,
                                                      tileColor: Colors
                                                          .lightBlueAccent,
                                                      iconColor: Colors.black,
                                                      textColor: SharedWidgets
                                                          .textColor(
                                                              context: context),
                                                      leading: SizedBox(
                                                        width: 40,
                                                        height: 40,
                                                        child: IconButton(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          onPressed: () =>
                                                              showGeneralDialog(
                                                            context: context,
                                                            // barrierColor: Colors
                                                            //     .black12
                                                            //     .withOpacity(
                                                            //         0.6), // Background color
                                                            barrierDismissible:
                                                                false,
                                                            barrierLabel:
                                                                'Dialog',
                                                            transitionDuration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        0),
                                                            pageBuilder:
                                                                (_, __, ___) {
                                                              return ScrollMatrixPage(
                                                                index: index,
                                                                name: i['name'],
                                                                translations:
                                                                    translations,
                                                                minDesktopSize:
                                                                    minDesktopSize,
                                                                close: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          icon:
                                                              SvgPicture.asset(
                                                            'assets/svg/8-8-led-matrix-display-unit.svg',
                                                            allowDrawingOutsideViewBox:
                                                                false,
                                                            fit: BoxFit.cover,
                                                            clipBehavior:
                                                                Clip.hardEdge,
                                                          ),
                                                        ),
                                                      ),
                                                      title: Text(
                                                        i['name'],
                                                        softWrap: false,
                                                        maxLines: 1,
                                                        style: (Platform
                                                                    .isMacOS ||
                                                                Platform
                                                                    .isWindows ||
                                                                Platform
                                                                    .isLinux)
                                                            ? const TextStyle(
                                                                fontSize: 16.0)
                                                            : const TextStyle(
                                                                fontSize: 14.0),
                                                      ),
                                                      subtitle: Text(
                                                        devices[index],
                                                        softWrap: false,
                                                        maxLines: 1,
                                                        style: (Platform
                                                                    .isMacOS ||
                                                                Platform
                                                                    .isWindows ||
                                                                Platform
                                                                    .isLinux)
                                                            ? const TextStyle(
                                                                fontSize: 13.0)
                                                            : const TextStyle(
                                                                fontSize: 11.0),
                                                      ),
                                                      isThreeLine: true,
                                                      trailing: Platform.isMacOS ||
                                                              Platform
                                                                  .isWindows ||
                                                              Platform.isLinux
                                                          ? Row(
                                                              // desktop variant
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  '${translations['deviceListTime'] ?? 'time'}: ${getFormattedDateString(date: i['time'])}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${i['playcount']}  ',
                                                                  softWrap:
                                                                      true,
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .fade,
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'configButtonText'] ??
                                                                        'Config',
                                                                    noBackground:
                                                                        true,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .settings,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return ConfigPage(
                                                                          name:
                                                                              i['name'],
                                                                          ip: devices[
                                                                              index],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'controlButtonText'] ??
                                                                        'Control',
                                                                    noBackground:
                                                                        true,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .control_camera,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return ControlPage(
                                                                          ip: devices[
                                                                              index],
                                                                          name:
                                                                              i['name'],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'messageButtonText'] ??
                                                                        'Message',
                                                                    noBackground:
                                                                        true,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .message_outlined,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return MessagePage(
                                                                          ip: devices[
                                                                              index],
                                                                          name:
                                                                              i['name'],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'liveControlButtonText'] ??
                                                                        'Live Control',
                                                                    noBackground:
                                                                        true,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .visibility_outlined,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return LiveControlPage(
                                                                          ip: devices[
                                                                              index],
                                                                          name:
                                                                              i['name'],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (moreInfo ==
                                                                    true)
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        IconButtonElement(
                                                                      label: translations[
                                                                              'infoButtonText'] ??
                                                                          'Monitoring',
                                                                      noBackground:
                                                                          true,
                                                                      withCircle:
                                                                          true,
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .info_outline,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                      moreInfo:
                                                                          true,
                                                                      onPressed:
                                                                          () =>
                                                                              showGeneralDialog(
                                                                        context:
                                                                            context,
                                                                        // barrierColor: Colors
                                                                        //     .black12
                                                                        //     .withOpacity(0.6), // Background color
                                                                        barrierDismissible:
                                                                            false,
                                                                        barrierLabel:
                                                                            'Dialog',
                                                                        transitionDuration:
                                                                            const Duration(milliseconds: 0),
                                                                        pageBuilder: (_,
                                                                            __,
                                                                            ___) {
                                                                          return InfoPage(
                                                                            name:
                                                                                i['name'],
                                                                            ip: devices[index],
                                                                            close:
                                                                                () {
                                                                              Navigator.pop(context);
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                if (moreInfo ==
                                                                    true)
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        IconButtonElement(
                                                                      label: translations[
                                                                              'logButtonText'] ??
                                                                          'Log',
                                                                      noBackground:
                                                                          true,
                                                                      withCircle:
                                                                          true,
                                                                      icon: Icon(
                                                                          Icons
                                                                              .terminal,
                                                                          color:
                                                                              Colors.white),
                                                                      moreInfo:
                                                                          true,
                                                                      onPressed:
                                                                          () =>
                                                                              showGeneralDialog(
                                                                        context:
                                                                            context,
                                                                        // barrierColor: Colors
                                                                        //     .black12
                                                                        //     .withOpacity(0.6), // Background color
                                                                        barrierDismissible:
                                                                            false,
                                                                        barrierLabel:
                                                                            'Dialog',
                                                                        transitionDuration:
                                                                            const Duration(milliseconds: 0),
                                                                        pageBuilder: (_,
                                                                            __,
                                                                            ___) {
                                                                          return LogPage(
                                                                            name:
                                                                                i['name'],
                                                                            ip: devices[index],
                                                                            close:
                                                                                () {
                                                                              Navigator.pop(context);
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            )
                                                          : orientation ==
                                                                      Orientation
                                                                          .portrait &&
                                                                  moreInfo ==
                                                                      true
                                                              ? Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        ...mobileButtons1(
                                                                            orientation,
                                                                            i,
                                                                            zoneName,
                                                                            index)
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8.0),
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        ...mobileButtons2(
                                                                            orientation,
                                                                            i,
                                                                            zoneName,
                                                                            index)
                                                                      ],
                                                                    )
                                                                  ],
                                                                )
                                                              : Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    ...mobileButtons1(
                                                                        orientation,
                                                                        i,
                                                                        zoneName,
                                                                        index),
                                                                    ...mobileButtons2(
                                                                        orientation,
                                                                        i,
                                                                        zoneName,
                                                                        index),
                                                                  ],
                                                                ),
                                                    ),
                                                    Positioned(
                                                        top: 60,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16.0),
                                                          child: NotificationListener<
                                                              SizeChangedLayoutNotification>(
                                                            onNotification:
                                                                (notification) {
                                                              updateSizes(
                                                                  'NotificationListener');
                                                              build(context);
                                                              return false;
                                                            },
                                                            child:
                                                                SizeChangedLayoutNotifier(
                                                              child: SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    (orientation == Orientation.portrait &&
                                                                            moreInfo ==
                                                                                true
                                                                        ? 130
                                                                        : 30),
                                                                key: ValueKey(
                                                                    'TextScrollWrapper-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                child:
                                                                    TextScroll(
                                                                  '${replaceCodes(i['displaystr'])}    ////    ',
                                                                  key: ValueKey(
                                                                      'TextScroll-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                  style:
                                                                      TextStyle(
                                                                    color: SharedWidgets.textColor(
                                                                        context:
                                                                            context),
                                                                  ),
                                                                  fadedBorder:
                                                                      true,
                                                                  fadeBorderSide:
                                                                      FadeBorderSide
                                                                          .right,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ))
                                                  ],
                                                ),
                                              );
                                            }),
                              ),
                              if (SharedWidgets.inIosStyle())
                                const SizedBox(height: 14.0),
                              if (height > minDesktopSize.height + 75)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: Platform.isMacOS ||
                                              Platform.isWindows ||
                                              Platform.isLinux
                                          ? 16.0
                                          : 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconTextButtonElement(
                                        onMacAsText: true,
                                        icon: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Icon(
                                            Icons.download,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ),
                                        label:
                                            translations['exportButtonText'] ??
                                                'export',
                                        onPressed: saveIdle == true ||
                                                idle == true ||
                                                devices.isEmpty
                                            ? null
                                            : () async {
                                                setState(() {
                                                  saveIdle = true;
                                                });
                                                bool? valid = await mainBloc
                                                    .exportDevicesData();
                                                setState(() {
                                                  saveIdle = false;
                                                });
                                                if (valid == null) {
                                                  return;
                                                }
                                                if (valid == true) {
                                                  if (context.mounted &&
                                                      !SharedWidgets
                                                          .inMacosStyle() &&
                                                      !SharedWidgets
                                                          .inIosStyle()) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                      content: Text(translations[
                                                              'exportDoneMessage'] ??
                                                          'export successfully done'),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ));
                                                  }
                                                } else {
                                                  if (context.mounted &&
                                                      !SharedWidgets
                                                          .inMacosStyle() &&
                                                      !SharedWidgets
                                                          .inIosStyle()) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                      content: Text(translations[
                                                              'exportFailedMessage'] ??
                                                          'export failed!'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ));
                                                  }
                                                }
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              if (SharedWidgets.inIosStyle())
                                const SizedBox(height: 14.0),
                            ],
                          ),
                        ),
                      );
                    });
                  });
            });
      });

  stack(BuildContext context) => Stack(
        children: <Widget>[
          body(),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
            top: 0.0,
            bottom: 0.0,
            left: _isDrawerOpen
                ? 0.0
                : -(MediaQuery.of(context).size.width / 3 * 2 + 100),
            child: Container(
              width: MediaQuery.of(context).size.width / 3 * 2,
              height: double.infinity,
              decoration: BoxDecoration(
                color: SharedWidgets.windowBackgroundColor(context: context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5.0,
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: height,
                    color:
                        Colors.transparent, // background color of burger menu
                    child: Stack(
                      children: <Widget>[
                        burgerMenu(),
                        Positioned(
                          top: 14.0,
                          left: 10.0,
                          child: GestureDetector(
                            onTap: () => setState(() => _isDrawerOpen = false),
                            child: Icon(
                              CupertinoIcons.clear,
                              color: Colors.white,
                              size: 30.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (SharedWidgets.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: SharedWidgets.brightness(),
            middle: Text(title),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child:
                  Icon(Icons.menu, color: _isDrawerOpen ? Colors.grey : null),
              onPressed: () =>
                  _isDrawerOpen ? null : setState(() => _isDrawerOpen = true),
            ),
          ),
          child: SafeArea(
            child: stack(context),
          ),
        ),
      );
    }
    return SharedWidgets.inMacosStyle()
        ? MacosScaffold(
            toolBar: ToolBar(
              title: Center(child: Text(title)),
              titleWidth: 1000.0,
              actions: [
                const ToolBarSpacer(),
                ToolBarIconButton(
                  label: "",
                  icon: Icon(
                    FontAwesomeIcons.arrowsLeftRight,
                    size: 16.0,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
                  ),
                  onPressed: () =>
                      mainBloc.windowResizeToFullWidthAndMinimumHeight(
                          minDesktopSize: minDesktopSize),
                  showLabel: false,
                ),
                ToolBarIconButton(
                  label: "",
                  icon: Icon(
                    FontAwesomeIcons.minimize,
                    size: 16.0,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
                  ),
                  onPressed: () =>
                      windowManager.setSize(standardDesktopSize, animate: true),
                  showLabel: false,
                ),
                ToolBarIconButton(
                  label: "",
                  icon: Icon(
                    FontAwesomeIcons.maximize,
                    size: 16.0,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
                  ),
                  onPressed: () => windowManager.maximize(),
                  showLabel: false,
                ),
                const ToolBarSpacer(),
              ],
            ),
            children: [
              ContentArea(
                builder: ((context, scrollController) {
                  return Material(
                    child: MacosWindow(
                      child: body(),
                    ),
                  );
                }),
              ),
            ],
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: IconButton(
                          iconSize: 16.0,
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                                  minDesktopSize: minDesktopSize),
                          icon: Icon(
                            FontAwesomeIcons.arrowsLeftRight,
                            color: SharedWidgets.toolbarResizeButtonColor(
                                context: context),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            right: Platform.isMacOS ? 16.0 : 4.0),
                        child: IconButton(
                          iconSize: 16.0,
                          padding: EdgeInsets.zero,
                          onPressed: () => windowManager
                              .setSize(standardDesktopSize, animate: true),
                          icon: Icon(
                            FontAwesomeIcons.minimize,
                            color: SharedWidgets.toolbarResizeButtonColor(
                                context: context),
                          ),
                        ),
                      ),
                      if (Platform.isMacOS)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: IconButton(
                            iconSize: 16.0,
                            padding: EdgeInsets.zero,
                            onPressed: () => windowManager.maximize(),
                            icon: Icon(
                              FontAwesomeIcons.maximize,
                              color: SharedWidgets.toolbarResizeButtonColor(
                                  context: context),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            drawer: SharedWidgets.inIosStyle() ||
                    Platform.isAndroid ||
                    Platform.isFuchsia
                ? burgerMenu()
                : null,
            body: body());
  }
}

class MenuItem extends StatelessWidget {
  final Icon icon;
  final String label;

  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon.icon,
            color: Color(0xFFB42827),
          ),
          SizedBox(
            width: 8.0,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
