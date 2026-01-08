import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/ui/layout/horizontal_slider.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class LiveControlPage extends StatefulWidget {
  final String name;
  final String ip;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final VoidCallback close;

  const LiveControlPage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.close,
  });

  @override
  State<LiveControlPage> createState() => LiveControlPageState();
}

class LiveControlPageState extends State<LiveControlPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  VoidCallback get close => widget.close;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> translations = {};
  Map<String, String> options = {};
  List<ConfigDefinitionItem> fieldDefinition = [];
  List<Widget> sliders = [];
  String title = '';
  String macosVersion = '';
  bool translationsLoaded = false;

  double verticalScrollDelay = 5;
  double verticalScrollMin = 1;
  double verticalScrollMax = 10;
  int verticalScrollDivisions = 9;
  String? verticalScrollDelayUnit;

  double scrollSpeed = 50;
  double scrollMin = 1;
  double scrollMax = 200;
  int scrollDivisions = 199;
  String? ledScrollDelayUnit;

  double contrast = 32;
  double contrastMin = 0;
  double contrastMax = 255;
  int contrastDivisions = 99;

  bool verticalOutput = false;
  bool controlVarInit = false;

  String selectedDeviceName = '';
  String? controlId;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late String selectedDeviceIp;

  @override
  void initState() {
    title = '$name : Live Control';
    selectedDeviceIp = ip;

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    mainBloc.getConfig(ip: selectedDeviceIp);

    super.initState();
  }

  Map<String, String> generateOptionsAndPreselect(
      {required List<String> devices, required Map<String, dynamic> infos}) {
    Map<String, String> options = {};

    for (String ip in devices) {
      String name = infos[ip]['name'];
      bool isCoverPlayer = infos[ip]['display_cover'];
      if (!isCoverPlayer) {
        options.putIfAbsent(name, () => ip);
      }
    }

    return options;
  }

  buildSliders(
      {required String selectedDeviceIp, required Orientation orientation}) {
    return [
      if (verticalOutput == true)
        HorizontalSlider(
          key: ValueKey('SliderVerticalScrollDelay_$selectedDeviceIp'),
          label: translations['config']?['vertical_scroll_delay'] ??
              'Vertical scroll delay',
          sliderValue: verticalScrollDelay,
          labelWidth: 300,
          min: verticalScrollMin,
          max: verticalScrollMax,
          divisions: verticalScrollDivisions,
          valueType: translations['config']?[verticalScrollDelayUnit] ??
              verticalScrollDelayUnit ??
              translations['config']?['seconds'] ??
              'seconds',
          orientation: orientation,
          onChanged: (double value) {
            setState(() {
              verticalScrollDelay = value;
              mainBloc.saveLiveControl(
                ip: selectedDeviceIp,
                control: 'vertical_scroll_delay',
                value: verticalScrollDelay.floor().toString(),
              );
              mainBloc.getInfo(ip: selectedDeviceIp);
            });
          },
        ),
      HorizontalSlider(
        key: ValueKey('SliderScrollSpeed_$selectedDeviceIp'),
        label: verticalOutput == true
            ? translations['config'] != null &&
                    translations['config']['led_vertical_scroll_delay'] != null
                ? (translations['config']['led_vertical_scroll_delay']
                        as String)
                    .replaceAll('LED ', '')
                : 'Vertical scroll delay (line by line)'
            : translations['config'] != null &&
                    translations['config']['led_scroll_delay'] != null
                ? (translations['config']['led_scroll_delay'] as String)
                    .replaceAll('LED ', '')
                : 'Horizontal scroll delay (line by line)',
        sliderValue: scrollSpeed,
        labelWidth: 300,
        min: scrollMin,
        max: scrollMax,
        divisions: scrollDivisions,
        valueType: translations['config']?[ledScrollDelayUnit] ??
            ledScrollDelayUnit ??
            translations['config']?['ms'] ??
            'ms',
        orientation: orientation,
        onChanged: (double value) {
          setState(() {
            scrollSpeed = value;
            mainBloc.saveLiveControl(
              ip: selectedDeviceIp,
              control: verticalOutput == true
                  ? 'led_vertical_scroll_delay'
                  : 'led_scroll_delay',
              value: scrollSpeed.floor().toString(),
            );
            mainBloc.getInfo(ip: selectedDeviceIp);
          });
        },
      ),
      HorizontalSlider(
        key: ValueKey('SliderContrast_$selectedDeviceIp'),
        label: translations['config']?['led_contrast'] != null
            ? (translations['config']?['led_contrast'] as String)
                .replaceAll('LED ', '')
            : 'contrast',
        sliderValue: contrast,
        labelWidth: 300,
        min: contrastMin,
        max: contrastMax,
        divisions: contrastDivisions,
        valueType: '%',
        orientation: orientation,
        onChanged: (double value) {
          setState(() {
            contrast = value;
            mainBloc.saveLiveControl(
              ip: selectedDeviceIp,
              control: 'led_contrast',
              value: contrast.floor().toString(),
            );
            mainBloc.getInfo(ip: selectedDeviceIp);
          });
        },
      ),
    ];
  }

  Widget body({
    required List<String> devices,
    required Map<String, dynamic> infos,
    required ConfigDefinition? definitions,
    required Map<String, String> options,
    required List<Widget> sliders,
    required Orientation orientation,
  }) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SelectBox(
              translations: translations,
              aligned: 'horizontal',
              label: '${translations['deviceName'] ?? 'device name'}:',
              placeholder:
                  '${translations['deviceSelectionPlaceholder'] ?? 'Select device'}...',
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
                    controlVarInit = false;
                    mainBloc.getConfig(ip: selectedDeviceIp);
                  });
                }
              },
            ),
            SizedBox(
                height: (Platform.isIOS || Platform.isAndroid) &&
                        orientation == Orientation.landscape
                    ? 0
                    : 48.0),
            ...sliders,
          ],
        )),
      );

  updateVars({
    required List<String> devices,
    required Map<String, dynamic> infos,
    required ConfigDefinition? definitions,
    required String selectedDeviceIp,
  }) {
    Map<String, dynamic> info = infos[selectedDeviceIp] ?? {};
    selectedDeviceName = info['name'];

    fieldDefinition = definitions != null
        ? definitions.area
            .firstWhereOrNull((ConfigDefinitionArea el) => el.name == 'SYSTEM')!
            .items
            .toList()
        : [];

    verticalScrollDelayUnit = fieldDefinition
        .firstWhereOrNull(
            (ConfigDefinitionItem el) => el.name == 'vertical_scroll_delay')
        ?.unit;

    ledScrollDelayUnit = fieldDefinition
        .firstWhereOrNull((ConfigDefinitionItem el) =>
            el.name ==
            (verticalOutput == true
                ? 'led_vertical_scroll_delay'
                : 'led_scroll_delay'))
        ?.unit;

    options = generateOptionsAndPreselect(devices: devices, infos: infos);

    if (!controlVarInit) {
      verticalOutput = info['vertical_output'];

      verticalScrollDelay =
          double.parse(info['vertical_scroll_delay'].toString());
      scrollSpeed = verticalOutput == true
          ? double.parse(info['led_vertical_scroll_delay'].toString())
          : double.parse(info['led_scroll_delay'].toString());
      scrollMax = verticalOutput == true ? 100 : 200;
      scrollDivisions = verticalOutput == true ? 100 : 200;

      contrast = double.parse(info['led_contrast'].toString());

      controlVarInit = true;
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
            title =
                '$name : ${translations['liveControlPageHeaderText'] ?? 'Live Control'}';
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

                macosVersion = mainState.macosVersion;
                List<String> devices = mainState.devices;
                Map<String, dynamic> infos = mainState.info;
                ConfigDefinition? definitions = mainState.definitions;

                updateVars(
                  devices: devices,
                  infos: infos,
                  definitions: definitions,
                  selectedDeviceIp: selectedDeviceIp,
                );

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  sliders = buildSliders(
                      selectedDeviceIp: selectedDeviceIp,
                      orientation: orientation);

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
                          child: body(
                            devices: devices,
                            infos: infos,
                            definitions: definitions,
                            options: options,
                            sliders: sliders,
                            orientation: orientation,
                          ),
                        ),
                      ),
                    );
                  }

                  return SharedWidgets.inMacosStyle()
                      ? PageWithToolbarMacStyle(
                          title: name,
                          standardDesktopSize: standardDesktopSize,
                          macosVersion: macosVersion,
                          body: body(
                            devices: devices,
                            infos: infos,
                            definitions: definitions,
                            options: options,
                            sliders: sliders,
                            orientation: orientation,
                          ),
                          resizeToFullWidth: () {
                            mainBloc.windowResizeToFullWidthAndMinimumHeight(
                                minDesktopSize: minDesktopSize);
                          },
                        )
                      : PageWithToolbarFlutterStyle(
                          scaffoldKey: scaffoldKey,
                          title: title,
                          showExpandableSpeedSlider: false,
                          scrollSpeedDevice: 1.0,
                          standardDesktopSize: standardDesktopSize,
                          body: body(
                            devices: devices,
                            infos: infos,
                            definitions: definitions,
                            options: options,
                            sliders: sliders,
                            orientation: orientation,
                          ),
                          resizeToFullWidth: () {
                            mainBloc.windowResizeToFullWidthAndMinimumHeight(
                                minDesktopSize: minDesktopSize);
                          },
                        );
                });
              });
        });
  }
}
