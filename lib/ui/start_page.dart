import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/control_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/burger_menu.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartPage extends StatefulWidget {
  const StartPage({
    super.key,
    required this.title,
    required this.options,
  });

  final String title;
  final Options options;

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  String get title => widget.title;

  final double treeFontSize = 12;
  Map<String, dynamic> translations = {};
  String aboutAppMessage = '';
  bool translationsLoaded = false;

  bool idle = false;
  bool saveIdle = false;
  List<String> devices = [];
  Map<String, dynamic> info = {};

  late Options options;
  late TranslationsBloc translationsBloc;
  late OptionsBloc optionsBloc;
  late String appVersionAndBuildNumber;

  @override
  void initState() {
    options = widget.options;
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    super.initState();
  }

  void openAboutModal(
          {required BuildContext context,
          required String aboutAppMessage,
          required Map<String, dynamic> translations}) =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          optionsBloc.openAboutModal(
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
            barrierColor: Colors.black12.withOpacity(0.6), // Background color
            barrierDismissible: false,
            barrierLabel: 'Dialog',
            transitionDuration: const Duration(milliseconds: 400),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Platform.isIOS || Platform.isAndroid || Platform.isFuchsia
          ? BlocBuilder(
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

                return Drawer(child: BurgerMenu(onClose: (String? key) {
                  if (key == 'about') {
                    openAboutModal(
                        context: context,
                        aboutAppMessage: aboutAppMessage,
                        translations: translations);
                  }
                  if (key == 'settings') {
                    openSettingsPage();
                  }
                }));
              })
          : null,
      body: BlocBuilder(
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
                bloc: optionsBloc,
                builder: (context, OptionsState optionsState) {
                  if (optionsState is! OptionsStateLoaded) {
                    return Container();
                  }

                  if (optionsState.ipStart == null ||
                      optionsState.ipEnd == null) {
                    openSettingsPage();
                  }

                  options = optionsState.options ?? options;
                  devices = optionsState.devices;
                  info = optionsState.info;
                  idle = optionsState.idle;

                  if (optionsState.searchFilter.isNotEmpty &&
                      devices.isNotEmpty) {
                    devices = devices
                        .where((String el) => (info[el]['name'] as String)
                            .toLowerCase()
                            .contains(
                                (optionsState.searchFilter['main'] as String)
                                    .toLowerCase()))
                        .toList();
                  }

                  // devices = [
                  //   // enable to test with multiple fake-devices
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

                  debugPrint(
                      'uuu state changed => rebuild, devices: ${devices.length}, idle: $idle');
                  return OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                    return Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          children: <Widget>[
                            Stack(
                              children: [
                                // options and searchfield area
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
                                        controller: optionsBloc
                                            .getSearchController(type: 'main'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (optionsState.logMessage.isNotEmpty)
                              SizedBox(
                                height: 300.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: Card(
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
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView(
                                              children: [
                                                Text(optionsState.logMessage),
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
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(8.0)),
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
                                                    child: Text(translations[
                                                            'scanNoFoundMessage'] ??
                                                        'no devices found'))),
                                          ],
                                        )
                                      : ListView.separated(
                                          key: ValueKey(
                                              'deviceList${devices.length}'),
                                          separatorBuilder: (context, index) =>
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
                                                if (i['channels'][controlId] ==
                                                    'webserver') {
                                                  zoneName = controlId;
                                                } else {
                                                  zoneName =
                                                      i['channels'][controlId];
                                                }
                                              }
                                            }

                                            return Container(
                                              color: const Color(0xffe0e0e0),
                                              child: Stack(
                                                children: [
                                                  ListTile(
                                                    minLeadingWidth: 28,
                                                    tileColor:
                                                        Colors.lightBlueAccent,
                                                    iconColor: Colors.black,
                                                    textColor: Colors.black,
                                                    leading: SizedBox(
                                                      width: 32,
                                                      height: 32,
                                                      child: SvgPicture.asset(
                                                        'assets/svg/8-8-led-matrix-display-unit.svg',
                                                        allowDrawingOutsideViewBox:
                                                            false,
                                                        fit: BoxFit.cover,
                                                        clipBehavior:
                                                            Clip.hardEdge,
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
                                                              Platform.isLinux)
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
                                                              Platform.isLinux)
                                                          ? const TextStyle(
                                                              fontSize: 13.0)
                                                          : const TextStyle(
                                                              fontSize: 11.0),
                                                    ),
                                                    isThreeLine: true,
                                                    trailing:
                                                        Platform.isMacOS ||
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
                                                                    '${translations['deviceListTime'] ?? 'time'}: ${i['time']}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${i['playcount']}  ',
                                                                    softWrap:
                                                                        true,
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .fade,
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        ElevatedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        showGeneralDialog(
                                                                          context:
                                                                              context,
                                                                          barrierColor: Colors
                                                                              .black12
                                                                              .withOpacity(0.6), // Background color
                                                                          barrierDismissible:
                                                                              false,
                                                                          barrierLabel:
                                                                              'Dialog',
                                                                          transitionDuration:
                                                                              const Duration(milliseconds: 400),
                                                                          pageBuilder: (_,
                                                                              __,
                                                                              ___) {
                                                                            return InfoPage(
                                                                              name: i['name'],
                                                                              ip: devices[index],
                                                                              close: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .info),
                                                                      label: Text(
                                                                          translations['infoButtonText'] ??
                                                                              'Info'),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        ElevatedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        showGeneralDialog(
                                                                          context:
                                                                              context,
                                                                          barrierColor: Colors
                                                                              .black12
                                                                              .withOpacity(0.6), // Background color
                                                                          barrierDismissible:
                                                                              false,
                                                                          barrierLabel:
                                                                              'Dialog',
                                                                          transitionDuration:
                                                                              const Duration(milliseconds: 400),
                                                                          pageBuilder: (_,
                                                                              __,
                                                                              ___) {
                                                                            return ConfigPage(
                                                                              name: i['name'],
                                                                              ip: devices[index],
                                                                              close: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .settings),
                                                                      label: Text(
                                                                          translations['configButtonText'] ??
                                                                              'Config'),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        ElevatedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        showGeneralDialog(
                                                                          context:
                                                                              context,
                                                                          barrierColor: Colors
                                                                              .black12
                                                                              .withOpacity(0.6), // Background color
                                                                          barrierDismissible:
                                                                              false,
                                                                          barrierLabel:
                                                                              'Dialog',
                                                                          transitionDuration:
                                                                              const Duration(milliseconds: 400),
                                                                          pageBuilder: (_,
                                                                              __,
                                                                              ___) {
                                                                            return LogPage(
                                                                              name: i['name'],
                                                                              ip: devices[index],
                                                                              close: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .remove_red_eye),
                                                                      label: Text(
                                                                          translations['logButtonText'] ??
                                                                              'Log'),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        ElevatedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        showGeneralDialog(
                                                                          context:
                                                                              context,
                                                                          barrierColor: Colors
                                                                              .black12
                                                                              .withOpacity(0.6), // Background color
                                                                          barrierDismissible:
                                                                              false,
                                                                          barrierLabel:
                                                                              'Dialog',
                                                                          transitionDuration:
                                                                              const Duration(milliseconds: 400),
                                                                          pageBuilder: (_,
                                                                              __,
                                                                              ___) {
                                                                            return ControlPage(
                                                                              ip: devices[index],
                                                                              name: i['name'],
                                                                              close: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .play_circle),
                                                                      label: Text(
                                                                          translations['controlButtonText'] ??
                                                                              'Control'),
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            : Row(
                                                                // mobile variant
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  if (orientation ==
                                                                      Orientation
                                                                          .portrait)
                                                                    Text(
                                                                        '${i['playcount']}',
                                                                        softWrap:
                                                                            true,
                                                                        overflow:
                                                                            TextOverflow
                                                                                .fade,
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                9)),
                                                                  if (orientation ==
                                                                      Orientation
                                                                          .landscape)
                                                                    Text(
                                                                      '${translations['deviceListTime'] ?? 'time'}: ${i['time']}\n${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'zone'}: ${i['playcount']}  ',
                                                                      softWrap:
                                                                          true,
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .fade,
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              11),
                                                                    ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        CircleAvatar(
                                                                      radius:
                                                                          15,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      child:
                                                                          IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        onPressed:
                                                                            () {
                                                                          showGeneralDialog(
                                                                            context:
                                                                                context,
                                                                            barrierColor:
                                                                                Colors.black12.withOpacity(0.6), // Background color
                                                                            barrierDismissible:
                                                                                false,
                                                                            barrierLabel:
                                                                                'Dialog',
                                                                            transitionDuration:
                                                                                const Duration(milliseconds: 400),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return InfoPage(
                                                                                name: i['name'],
                                                                                ip: devices[index],
                                                                                close: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons.info),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        CircleAvatar(
                                                                      radius:
                                                                          15,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      child:
                                                                          IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        onPressed:
                                                                            () {
                                                                          showGeneralDialog(
                                                                            context:
                                                                                context,
                                                                            barrierColor:
                                                                                Colors.black12.withOpacity(0.6), // Background color
                                                                            barrierDismissible:
                                                                                false,
                                                                            barrierLabel:
                                                                                'Dialog',
                                                                            transitionDuration:
                                                                                const Duration(milliseconds: 400),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return ConfigPage(
                                                                                name: i['name'],
                                                                                ip: devices[index],
                                                                                close: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons.settings),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        CircleAvatar(
                                                                      radius:
                                                                          15,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      child:
                                                                          IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        onPressed:
                                                                            () {
                                                                          showGeneralDialog(
                                                                            context:
                                                                                context,
                                                                            barrierColor:
                                                                                Colors.black12.withOpacity(0.6), // Background color
                                                                            barrierDismissible:
                                                                                false,
                                                                            barrierLabel:
                                                                                'Dialog',
                                                                            transitionDuration:
                                                                                const Duration(milliseconds: 400),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return LogPage(
                                                                                name: i['name'],
                                                                                ip: devices[index],
                                                                                close: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons.remove_red_eye),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        CircleAvatar(
                                                                      radius:
                                                                          15,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      child:
                                                                          IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        onPressed:
                                                                            () {
                                                                          showGeneralDialog(
                                                                            context:
                                                                                context,
                                                                            barrierColor:
                                                                                Colors.black12.withOpacity(0.6), // Background color
                                                                            barrierDismissible:
                                                                                false,
                                                                            barrierLabel:
                                                                                'Dialog',
                                                                            transitionDuration:
                                                                                const Duration(milliseconds: 400),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return ControlPage(
                                                                                ip: devices[index],
                                                                                name: i['name'],
                                                                                close: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons.play_circle),
                                                                      ),
                                                                    ),
                                                                  ),
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
                                                        child: SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width -
                                                                30,
                                                            child: TextScroll(
                                                                '${i['displaystr']}    ////    ')),
                                                      ))
                                                ],
                                              ),
                                            );
                                          }),
                            ),
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
                                  ElevatedButton.icon(
                                    icon: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Icon(
                                        Icons.download,
                                        color: Colors.white,
                                        size: 20.0,
                                      ),
                                    ),
                                    label: Text(
                                        translations['exportButtonText'] ??
                                            'export'),
                                    onPressed: saveIdle == true ||
                                            idle == true ||
                                            devices.isEmpty
                                        ? null
                                        : () async {
                                            setState(() {
                                              saveIdle = true;
                                            });
                                            bool? valid = await optionsBloc
                                                .exportDevicesData();
                                            setState(() {
                                              saveIdle = false;
                                            });
                                            if (valid == null) {
                                              return;
                                            }
                                            if (valid == true) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(translations[
                                                          'exportDoneMessage'] ??
                                                      'export successfully done'),
                                                  backgroundColor: Colors.green,
                                                ));
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(translations[
                                                          'exportFailedMessage'] ??
                                                      'export failed!'),
                                                  backgroundColor: Colors.red,
                                                ));
                                              }
                                            }
                                          },
                                  ),
                                ],
                              ),
                            ),
                            if (Platform.isIOS) const SizedBox(height: 14.0),
                          ],
                        ),
                      ),
                    );
                  });
                });
          }),
    );
  }
}
