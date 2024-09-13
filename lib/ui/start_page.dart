import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/control_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/labeled_checkbox.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartPage extends StatefulWidget {
  const StartPage({
    super.key,
    required this.title,
    required this.showOptions,
    required this.options,
  });

  final String title;
  final bool showOptions;
  final Options options;

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  String get title => widget.title;
  bool get showOptions => widget.showOptions;

  final double treeFontSize = 12;

  bool polling = false;
  bool idle = false;
  bool saveIdle = false;
  List<String> devices = [];
  Map<String, dynamic> info = {};

  late Options options;
  late OptionsBloc optionsBloc;

  @override
  void initState() {
    options = widget.options;
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: BlocBuilder(
          bloc: optionsBloc,
          builder: (context, OptionsState optionsState) {
            if (optionsState is! OptionsStateLoaded) {
              return Container();
            }

            if (optionsState.ipStart == null || optionsState.ipEnd == null) {
              SchedulerBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  await showGeneralDialog(
                    context: context,
                    barrierColor:
                        Colors.black12.withOpacity(0.6), // Background color
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
            }

            options = optionsState.options ?? options;
            devices = optionsState.devices;
            info = optionsState.info;
            idle = optionsState.idle;

            if (optionsState.searchFilter.isNotEmpty && devices.isNotEmpty) {
              devices = devices
                  .where((String el) => (info[el]['name'] as String)
                      .toLowerCase()
                      .contains((optionsState.searchFilter['main'] as String)
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

            polling = options.polling;

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
                            padding:
                                const EdgeInsets.only(bottom: 8.0, right: 8.0),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              direction: Axis.horizontal,
                              children: [
                                if (showOptions == true)
                                  Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(
                                      left: 8.0,
                                      bottom: 4.0,
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(left: 10.0),
                                            child: Text(
                                              'Options:',
                                              style: TextStyle(
                                                  fontStyle: FontStyle.normal,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          LabeledCheckbox(
                                            label: "polling",
                                            value: options.polling,
                                            onChanged: (bool newValue) {
                                              optionsBloc.setOptionsPolling(
                                                  polling: newValue);
                                            },
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            padding: const EdgeInsets.all(4.0),
                                            constraints: const BoxConstraints(),
                                            splashRadius: 1,
                                            onPressed: () {
                                              optionsBloc.resetOptions();
                                            },
                                            color: Colors.black45,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                SearchField(
                                  type: 'main',
                                  controller: optionsBloc.getSearchController(
                                      type: 'main'),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Card(
                              color: Colors.lightBlueAccent,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        'Debug Messages:',
                                        style: TextStyle(
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
                            ? const LoadingIndicator(
                                message: 'scan for devices')
                            : devices.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                          width: 150,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.deepOrange,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(8.0)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.deepOrange
                                                    .withOpacity(0.15),
                                                spreadRadius: 1,
                                                blurRadius: 8,
                                                offset: const Offset(3,
                                                    3), // changes position of shadow
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                              child: const Text(
                                                  'no devices found'))),
                                    ],
                                  )
                                : ListView.separated(
                                    key:
                                        ValueKey('deviceList${devices.length}'),
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                    itemCount: devices.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      dynamic i = info[devices[index]];

                                      String zoneName = '';
                                      if (i['control_id'] != null) {
                                        String controlId = i['control_id'];
                                        if (i['channels'] != null &&
                                            i['channels'][controlId] != null) {
                                          if (i['channels'][controlId] ==
                                              'webserver') {
                                            zoneName = controlId;
                                          } else {
                                            zoneName = i['channels'][controlId];
                                          }
                                        }
                                      }

                                      return Container(
                                        color: const Color(0xffe0e0e0),
                                        child: Stack(
                                          children: [
                                            ListTile(
                                              minLeadingWidth: 28,
                                              tileColor: Colors.lightBlueAccent,
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
                                                  clipBehavior: Clip.hardEdge,
                                                ),
                                              ),
                                              title: Text(
                                                i['name'],
                                                softWrap: false,
                                                maxLines: 1,
                                                style: (Platform.isMacOS ||
                                                        Platform.isWindows ||
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
                                                style: (Platform.isMacOS ||
                                                        Platform.isWindows ||
                                                        Platform.isLinux)
                                                    ? const TextStyle(
                                                        fontSize: 13.0)
                                                    : const TextStyle(
                                                        fontSize: 11.0),
                                              ),
                                              isThreeLine: true,
                                              trailing: Platform.isMacOS ||
                                                      Platform.isWindows ||
                                                      Platform.isLinux
                                                  ? Row(
                                                      // desktop variant
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'time: ${i['time']}  |  zone: $zoneName  |  playcount: ${i['playcount']}  ',
                                                          softWrap: true,
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow.fade,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () {
                                                              showGeneralDialog(
                                                                context:
                                                                    context,
                                                                barrierColor: Colors
                                                                    .black12
                                                                    .withOpacity(
                                                                        0.6), // Background color
                                                                barrierDismissible:
                                                                    false,
                                                                barrierLabel:
                                                                    'Dialog',
                                                                transitionDuration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                                pageBuilder: (_,
                                                                    __, ___) {
                                                                  return InfoPage(
                                                                    name: i[
                                                                        'name'],
                                                                    ip: devices[
                                                                        index],
                                                                    close: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(
                                                                Icons.info),
                                                            label: const Text(
                                                                'Info'),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () {
                                                              showGeneralDialog(
                                                                context:
                                                                    context,
                                                                barrierColor: Colors
                                                                    .black12
                                                                    .withOpacity(
                                                                        0.6), // Background color
                                                                barrierDismissible:
                                                                    false,
                                                                barrierLabel:
                                                                    'Dialog',
                                                                transitionDuration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                                pageBuilder: (_,
                                                                    __, ___) {
                                                                  return ConfigPage(
                                                                    name: i[
                                                                        'name'],
                                                                    ip: devices[
                                                                        index],
                                                                    close: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(
                                                                Icons.settings),
                                                            label: const Text(
                                                                'Config'),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () {
                                                              showGeneralDialog(
                                                                context:
                                                                    context,
                                                                barrierColor: Colors
                                                                    .black12
                                                                    .withOpacity(
                                                                        0.6), // Background color
                                                                barrierDismissible:
                                                                    false,
                                                                barrierLabel:
                                                                    'Dialog',
                                                                transitionDuration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                                pageBuilder: (_,
                                                                    __, ___) {
                                                                  return LogPage(
                                                                    name: i[
                                                                        'name'],
                                                                    ip: devices[
                                                                        index],
                                                                    close: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(Icons
                                                                .remove_red_eye),
                                                            label: const Text(
                                                                'Log'),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () {
                                                              showGeneralDialog(
                                                                context:
                                                                    context,
                                                                barrierColor: Colors
                                                                    .black12
                                                                    .withOpacity(
                                                                        0.6), // Background color
                                                                barrierDismissible:
                                                                    false,
                                                                barrierLabel:
                                                                    'Dialog',
                                                                transitionDuration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                                pageBuilder: (_,
                                                                    __, ___) {
                                                                  return ControlPage(
                                                                    ip: devices[
                                                                        index],
                                                                    name: i[
                                                                        'name'],
                                                                    close: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(Icons
                                                                .play_circle),
                                                            label: const Text(
                                                                'Control'),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Row(
                                                      // mobile variant
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (orientation ==
                                                            Orientation
                                                                .portrait)
                                                          Text(
                                                              '${i['playcount']}',
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .fade,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          9)),
                                                        if (orientation ==
                                                            Orientation
                                                                .landscape)
                                                          Text(
                                                            'time: ${i['time']}\nzone: $zoneName  |  playcount: ${i['playcount']}  ',
                                                            softWrap: true,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .fade,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        11),
                                                          ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: CircleAvatar(
                                                            radius: 15,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: IconButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              onPressed: () {
                                                                showGeneralDialog(
                                                                  context:
                                                                      context,
                                                                  barrierColor: Colors
                                                                      .black12
                                                                      .withOpacity(
                                                                          0.6), // Background color
                                                                  barrierDismissible:
                                                                      false,
                                                                  barrierLabel:
                                                                      'Dialog',
                                                                  transitionDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              400),
                                                                  pageBuilder:
                                                                      (_, __,
                                                                          ___) {
                                                                    return InfoPage(
                                                                      name: i[
                                                                          'name'],
                                                                      ip: devices[
                                                                          index],
                                                                      close:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
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
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: CircleAvatar(
                                                            radius: 15,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: IconButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              onPressed: () {
                                                                showGeneralDialog(
                                                                  context:
                                                                      context,
                                                                  barrierColor: Colors
                                                                      .black12
                                                                      .withOpacity(
                                                                          0.6), // Background color
                                                                  barrierDismissible:
                                                                      false,
                                                                  barrierLabel:
                                                                      'Dialog',
                                                                  transitionDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              400),
                                                                  pageBuilder:
                                                                      (_, __,
                                                                          ___) {
                                                                    return ConfigPage(
                                                                      name: i[
                                                                          'name'],
                                                                      ip: devices[
                                                                          index],
                                                                      close:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                              icon: const Icon(
                                                                  Icons
                                                                      .settings),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: CircleAvatar(
                                                            radius: 15,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: IconButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              onPressed: () {
                                                                showGeneralDialog(
                                                                  context:
                                                                      context,
                                                                  barrierColor: Colors
                                                                      .black12
                                                                      .withOpacity(
                                                                          0.6), // Background color
                                                                  barrierDismissible:
                                                                      false,
                                                                  barrierLabel:
                                                                      'Dialog',
                                                                  transitionDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              400),
                                                                  pageBuilder:
                                                                      (_, __,
                                                                          ___) {
                                                                    return LogPage(
                                                                      name: i[
                                                                          'name'],
                                                                      ip: devices[
                                                                          index],
                                                                      close:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                              icon: const Icon(Icons
                                                                  .remove_red_eye),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: CircleAvatar(
                                                            radius: 15,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: IconButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              onPressed: () {
                                                                showGeneralDialog(
                                                                  context:
                                                                      context,
                                                                  barrierColor: Colors
                                                                      .black12
                                                                      .withOpacity(
                                                                          0.6), // Background color
                                                                  barrierDismissible:
                                                                      false,
                                                                  barrierLabel:
                                                                      'Dialog',
                                                                  transitionDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              400),
                                                                  pageBuilder:
                                                                      (_, __,
                                                                          ___) {
                                                                    return ControlPage(
                                                                      ip: devices[
                                                                          index],
                                                                      name: i[
                                                                          'name'],
                                                                      close:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                              icon: const Icon(Icons
                                                                  .play_circle),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                            Positioned(
                                                top: 60,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16.0),
                                                  child: SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
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
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                              label: const Text('export'),
                              onPressed: saveIdle == true ||
                                      idle == true ||
                                      devices.isEmpty
                                  ? null
                                  : () async {
                                      setState(() {
                                        saveIdle = true;
                                      });
                                      bool? valid =
                                          await optionsBloc.exportDevicesData();
                                      setState(() {
                                        saveIdle = false;
                                      });
                                      if (valid == null) {
                                        return;
                                      }
                                      if (valid == true) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                "export successfully done"),
                                            backgroundColor: Colors.green,
                                          ));
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text("export failed!"),
                                            backgroundColor: Colors.red,
                                          ));
                                        }
                                      }
                                    },
                            ),
                            if (!polling) ...[
                              const SizedBox(width: 32.0),
                              ElevatedButton.icon(
                                icon: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                                ),
                                label: const Text('refresh'),
                                onPressed: () {
                                  optionsBloc.searching(idle: true);
                                },
                              ),
                            ]
                          ],
                        ),
                      ),
                      if (Platform.isIOS) const SizedBox(height: 14.0),
                    ],
                  ),
                ),
              );
            });
          }),
    );
  }
}
