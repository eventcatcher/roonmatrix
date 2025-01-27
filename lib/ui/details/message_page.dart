import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/message_writer.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class MessagePage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const MessagePage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  final double buttonSize =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux ? 128.0 : 88.0;
  final bool showButtonUp = false;

  Map<String, dynamic> translations = {};
  String title = '';
  bool translationsLoaded = false;

  String selectedDeviceName = '';

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late String selectedDeviceIp;

  @override
  void initState() {
    title = '$name : Control';
    selectedDeviceIp = ip;

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: selectedDeviceIp);

    super.initState();
  }

  Map<String, String> generateOptionsAndPreselect(
      {required List<String> devices, required Map<String, dynamic> infos}) {
    Map<String, String> options = {};

    for (String ip in devices) {
      String name = infos[ip]['name'];
      options.putIfAbsent(name, () => ip);
    }

    return options;
  }

  Widget selectBox(options) => SelectBox(
      translations: translations,
      aligned: 'horizontal',
      label: '${translations['deviceName'] ?? 'device name'}:',
      placeholder:
          '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
      inRow: false,
      noVerticalSpace: false,
      readOnly: false,
      selected: selectedDeviceName,
      options: options,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedDeviceName = newValue;
            selectedDeviceIp = options[newValue]!;
          });
        }
      });

  Widget body({
    required Orientation orientation,
    required Map<String, String> options,
  }) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: orientation == Orientation.portrait ||
                  Platform.isMacOS ||
                  Platform.isWindows ||
                  Platform.isLinux
              ? Column(
                  // portrait view
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    selectBox(options),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: MessageWriter(
                        name: name,
                        ip: selectedDeviceIp,
                        translations: translations,
                      ),
                    ),
                  ],
                )
              : Row(
                  // landscape view
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        children: [
                          MessageWriter(
                            name: name,
                            ip: selectedDeviceIp,
                            translations: translations,
                            firstRowChild: Platform.isIOS ||
                                    Platform.isAndroid ||
                                    Platform.isFuchsia
                                ? selectBox(options)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
            title =
                '$name : ${translations['messagePageHeaderText'] ?? 'Message'}';
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
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
                    toolBar: ToolBar(
                      title: Text(
                        title,
                        style: TextStyle(
                          color: SharedWidgets.textColor(context: context),
                        ),
                      ),
                      titleWidth: 1000.0,
                      leading: MacosBackButton(
                        onPressed: () => Navigator.pop(context),
                        fillColor: Colors.transparent,
                      ),
                      actions: [],
                    ),
                    children: [
                      ContentArea(
                        builder: ((context, scrollController) {
                          return MacosWindow(
                            child: Material(
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
                    ),
                    body: const SizedBox());
          }

          return BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return const SizedBox();
                }

                List<String> devices = mainState.devices;
                Map<String, dynamic> infos = mainState.info;
                Map<String, dynamic> info = infos[selectedDeviceIp] ?? {};
                selectedDeviceName = info['name'];
                Map<String, String> options =
                    generateOptionsAndPreselect(devices: devices, infos: infos);

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  if (SharedWidgets.inIosStyle()) {
                    return Material(
                      child: CupertinoPageScaffold(
                        navigationBar: CupertinoNavigationBar(
                          brightness: SharedWidgets.brightness(),
                          middle: Text(title),
                          leading: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: CupertinoNavigationBarBackButton(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        child: SafeArea(
                          child:
                              body(orientation: orientation, options: options),
                        ),
                      ),
                    );
                  }

                  return SharedWidgets.inMacosStyle()
                      ? MacosScaffold(
                          toolBar: ToolBar(
                            title: Text(title),
                            titleWidth: 200.0,
                            leading: MacosBackButton(
                              onPressed: () => Navigator.pop(context),
                              fillColor: Colors.transparent,
                            ),
                            actions: [],
                          ),
                          children: [
                            ContentArea(
                              builder: ((context, scrollController) {
                                return Material(
                                  child: MacosWindow(
                                    child: body(
                                        orientation: orientation,
                                        options: options),
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
                          body:
                              body(orientation: orientation, options: options),
                        );
                });
              });
        });
  }
}
