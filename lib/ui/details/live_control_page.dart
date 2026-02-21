import 'dart:io';

import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/ui/layout/horizontal_slider.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class LiveControlPage extends StatefulWidget {
  final String name;
  final String ip;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const LiveControlPage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<LiveControlPage> createState() => LiveControlPageState();
}

class LiveControlPageState extends State<LiveControlPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> translations = {};
  Map<String, String> options = {};
  List<ConfigDefinitionItem> fieldDefinition = [];
  List<Widget> sliders = [];
  String title = '';
  String macosVersion = '';
  bool translationsLoaded = false;

  double verticalScrollMin = 1;
  double verticalScrollMax = 10;
  int verticalScrollDivisions = 9;
  double verticalScrollDelay = 5;
  String? verticalScrollDelayUnit;

  double scrollMin = 12;
  double scrollMax = 50;
  int scrollDivisions = 38;
  double scrollSpeed = 30;
  String? ledScrollDelayUnit;

  double contrastMin = 0;
  double contrastMax = 255;
  final int contrastDivisions = 100;
  final Duration debounceSetLiveControlDuration = Duration(milliseconds: 200);
  final Duration debounceGetInfoDuration = Duration(milliseconds: 1000);
  double contrast = 32;

  bool verticalOutput = false;
  bool controlVarInit = false;

  String? selectedDeviceName;

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

  List<Widget> buildSliders({
    required String selectedDeviceIp,
    required Orientation orientation,
    double labelWidth = 300,
  }) {
    bool smallHeight =
        MediaQuery.of(context).size.height < Globals.heightSwitchBoundarySmall;
    return [
      if (verticalOutput == true)
        Flexible(
          child: HorizontalSlider(
            key: ValueKey('SliderVerticalScrollDelay-$selectedDeviceIp'),
            label: translations['config']?['vertical_scroll_delay'] ??
                'Vertical scroll delay',
            smallHeight: smallHeight,
            sliderValue: verticalScrollDelay,
            labelWidth: labelWidth,
            min: verticalScrollDelay < verticalScrollMin
                ? verticalScrollDelay
                : verticalScrollMin,
            max: verticalScrollDelay > verticalScrollMax
                ? verticalScrollDelay
                : verticalScrollMax,
            divisions: verticalScrollDivisions,
            valueType: translations['config']?[verticalScrollDelayUnit] ??
                verticalScrollDelayUnit ??
                translations['config']?['seconds'] ??
                'seconds',
            orientation: orientation,
            onChanged: (double value) {
              EasyDebounce.debounce(
                'livecontrol-vScrollSetLiveControl-debouncer',
                debounceSetLiveControlDuration,
                () {
                  mainBloc.saveLiveControl(
                    ip: selectedDeviceIp,
                    control: 'vertical_scroll_delay',
                    value: value.floor().toString(),
                  );
                },
              );
              EasyDebounce.debounce(
                'livecontrol-vScrollGetinfo-debouncer',
                debounceGetInfoDuration,
                () {
                  mainBloc.getInfo(ip: selectedDeviceIp);
                },
              );
              setState(() {
                verticalScrollDelay = value;
              });
            },
          ),
        ),
      Flexible(
        child: HorizontalSlider(
          key: ValueKey('SliderScrollSpeed-$selectedDeviceIp'),
          label: verticalOutput == true
              ? translations['config'] != null &&
                      translations['config']['led_vertical_scroll_delay'] !=
                          null
                  ? (translations['config']['led_vertical_scroll_delay']
                          as String)
                      .replaceAll('LED ', '')
                  : 'Vertical scroll delay (line by line)'
              : translations['config'] != null &&
                      translations['config']['led_scroll_delay'] != null
                  ? (translations['config']['led_scroll_delay'] as String)
                      .replaceAll('LED ', '')
                  : 'Horizontal scroll delay (line by line)',
          smallHeight: smallHeight,
          sliderValue: scrollSpeed,
          labelWidth: labelWidth,
          min: scrollSpeed < scrollMin ? scrollSpeed : scrollMin,
          max: scrollSpeed > scrollMax ? scrollSpeed : scrollMax,
          divisions: scrollDivisions,
          valueType: translations['config']?[ledScrollDelayUnit] ??
              ledScrollDelayUnit ??
              translations['config']?['ms'] ??
              'ms',
          orientation: orientation,
          onChanged: (double value) {
            EasyDebounce.debounce(
              'livecontrol-scrollSpeedSetLiveControl-debouncer',
              debounceSetLiveControlDuration,
              () {
                mainBloc.saveLiveControl(
                  ip: selectedDeviceIp,
                  control: verticalOutput == true
                      ? 'led_vertical_scroll_delay'
                      : 'led_scroll_delay',
                  value: value.floor().toString(),
                );
              },
            );
            EasyDebounce.debounce(
              'livecontrol-scrollSpeedGetinfo-debouncer',
              debounceGetInfoDuration,
              () {
                mainBloc.getInfo(ip: selectedDeviceIp);
              },
            );
            setState(() {
              scrollSpeed = value;
            });
          },
        ),
      ),
      Flexible(
        child: HorizontalSlider(
          key: ValueKey('SliderContrast-$selectedDeviceIp'),
          label: translations['config']?['led_contrast'] != null
              ? (translations['config']?['led_contrast'] as String)
                  .replaceAll('LED ', '')
              : 'contrast',
          smallHeight: smallHeight,
          sliderValue: contrast,
          labelWidth: labelWidth,
          min: contrast < contrastMin ? contrast : contrastMin,
          max: contrast > contrastMax ? contrast : contrastMax,
          divisions: contrastDivisions,
          valueType: '%',
          orientation: orientation,
          onChanged: (double value) {
            EasyDebounce.debounce(
              'livecontrol-contrastSetLiveControl-debouncer',
              debounceSetLiveControlDuration,
              () {
                mainBloc.saveLiveControl(
                  ip: selectedDeviceIp,
                  control: 'led_contrast',
                  value: value.floor().toString(),
                );
              },
            );
            EasyDebounce.debounce(
              'livecontrol-contrastGetinfo-debouncer',
              debounceGetInfoDuration,
              () {
                mainBloc.getInfo(ip: selectedDeviceIp);
              },
            );
            setState(() {
              contrast = value;
            });
          },
        ),
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
  }) {
    if (selectedDeviceName == null || options[selectedDeviceName] == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      return SizedBox();
    }

    return Container(
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
                mainBloc.getConfig(ip: options[newValue]!);
                setState(() {
                  selectedDeviceName = newValue;
                  selectedDeviceIp = options[newValue]!;
                  controlVarInit = false;
                });
              }
            },
          ),
          SizedBox(
              height: (Platform.isIOS || Platform.isAndroid) &&
                      orientation == Orientation.landscape
                  ? 0
                  : 8.0),
          ...sliders,
        ],
      )),
    );
  }

  void updateVars({
    required List<String> devices,
    required Map<String, dynamic> infos,
    required ConfigDefinition? definitions,
    required String selectedDeviceIp,
  }) {
    Map<String, dynamic>? info = infos[selectedDeviceIp];
    selectedDeviceName = info?['name'];

    fieldDefinition = definitions != null
        ? definitions.area
            .firstWhereOrNull((ConfigDefinitionArea el) => el.name == 'SYSTEM')!
            .items
            .toList()
        : [];

    ConfigDefinitionItem? verticalScrollDelayDef =
        fieldDefinition.firstWhereOrNull(
            (ConfigDefinitionItem el) => el.name == 'vertical_scroll_delay');
    verticalScrollDelayUnit = verticalScrollDelayDef?.unit;
    if (verticalScrollDelayUnit != null &&
        verticalScrollDelayUnit!.contains('-')) {
      verticalScrollDelayUnit = '($verticalScrollDelayUnit)';
    }
    String? verticalScrollDelayType = verticalScrollDelayDef?.type.type;
    if (verticalScrollDelayType != null &&
        verticalScrollDelayType.startsWith('int(') &&
        verticalScrollDelayType.endsWith(')')) {
      List<String> verticalScrollDelayTypeParts = verticalScrollDelayType
          .replaceAll('int(', '')
          .replaceAll(')', '')
          .split(',');
      verticalScrollMin = double.parse(verticalScrollDelayTypeParts[0]);
      verticalScrollMax = double.parse(verticalScrollDelayTypeParts[1]);
      verticalScrollDivisions = (verticalScrollMax - verticalScrollMin).toInt();
    }

    ConfigDefinitionItem? scrollDelayDef = fieldDefinition.firstWhereOrNull(
        (ConfigDefinitionItem el) =>
            el.name ==
            (verticalOutput == true
                ? 'led_vertical_scroll_delay'
                : 'led_scroll_delay'));
    ledScrollDelayUnit = scrollDelayDef?.unit;
    if (ledScrollDelayUnit != null && ledScrollDelayUnit!.contains('-')) {
      ledScrollDelayUnit = '($ledScrollDelayUnit)';
    }
    String? scrollDelayType = scrollDelayDef?.type.type;
    if (scrollDelayType != null &&
        scrollDelayType.startsWith('int(') &&
        scrollDelayType.endsWith(')')) {
      List<String> scrollDelayTypeParts =
          scrollDelayType.replaceAll('int(', '').replaceAll(')', '').split(',');
      scrollMin = double.parse(scrollDelayTypeParts[0]);
      scrollMax = double.parse(scrollDelayTypeParts[1]);
      scrollDivisions = (scrollMax - scrollMin).toInt();
    }

    ConfigDefinitionItem? contrastDef = fieldDefinition.firstWhereOrNull(
        (ConfigDefinitionItem el) => el.name == 'led_contrast');
    String? contrastType = contrastDef?.type.type;
    if (contrastType != null &&
        contrastType.startsWith('int(') &&
        contrastType.endsWith(')')) {
      List<String> contrastTypeParts =
          contrastType.replaceAll('int(', '').replaceAll(')', '').split(',');
      contrastMin = double.parse(contrastTypeParts[0]);
      contrastMax = double.parse(contrastTypeParts[1]);
    }

    options = mainBloc.generateDeviceOptions(devices: devices, infos: infos);

    if (!controlVarInit) {
      if (info == null) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        try {
          verticalOutput = info['vertical_output'] ?? false;

          verticalScrollDelay =
              double.parse(info['vertical_scroll_delay'].toString());
          scrollSpeed = verticalOutput == true
              ? double.parse(info['led_vertical_scroll_delay'].toString())
              : double.parse(info['led_scroll_delay'].toString());

          contrast = double.parse(info['led_contrast'].toString());
        } catch (e) {
          if (kDebugMode) {
            debugPrint('LiveControlPage/updateVars => error: $e');
          }
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
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
                    toolBar: ToolBar(
                      title: Text(
                        title,
                        style: TextStyle(
                          color: ColorDefs.textColor(context: context),
                        ),
                      ),
                      titleWidth: Globals.extendedTitleWidth,
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

                  if (Globals.inIosStyle()) {
                    return Material(
                      child: CupertinoPageScaffold(
                        navigationBar: CupertinoNavigationBar(
                          brightness: Globals.brightness(),
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

                  return Globals.inMacosStyle()
                      ? PageWithToolbarMacStyle(
                          title: title,
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
