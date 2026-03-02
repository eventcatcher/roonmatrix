import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/ip_address_input_formatter.dart';
import 'package:roonmatrix/ui/helper/ip_input_formatter.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/switch_button.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class SettingsPage extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const SettingsPage({
    super.key,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController ipStart = TextEditingController();
  final TextEditingController ipEnd = TextEditingController();

  final double minIpFieldsInRowWidth = 400.0;

  Map<String, dynamic> translations = {};
  String title = '';
  String macosVersion = '';
  bool moreInfo = false;
  bool coverRowActive = false;
  bool coverRowArtist = false;
  bool coverRowAlbum = false;
  bool coverRowTrack = false;
  bool coverRowDynamicSize = false;
  bool verticalTickerActive = false;
  bool ledTickerInDeviceListActive = false;
  bool ledTickerOnTickerPageActive = false;
  bool forceTickerUpdateActive = false;

  bool translationsLoaded = false;
  bool rangeValid = false;
  bool loaded = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late SettingsBloc settingsBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);

    title = 'Settings';
    ipStart.text = '';
    ipEnd.text = '';

    super.initState();
  }

  Stream<String> ipChangeListener(TextEditingController controller) async* {
    while (true) {
      await Future.delayed(Duration(milliseconds: 100));
      yield controller.value.text;
    }
  }

  @override
  void dispose() {
    ipStart.dispose();
    ipEnd.dispose();
    super.dispose();
  }

  EditableSinglelineText fromField() => EditableSinglelineText(
        key: ValueKey('Setting-Start-$loaded}'),
        translations: translations,
        inputType: TextInputType.text,
        placeholder: '###.###.###.###',
        formatters: [
          IpInputFormatter.ipAddressInputFilter(),
          LengthLimitingTextInputFormatter(15),
          IpAddressInputFormatter()
        ],
        noCounter: true,
        maxLength: 15,
        label: translations['settingsPageIpScanRangeLabelFrom'] ?? 'from',
        text: ipStart.text,
        controller: ipStart,
        errorMessageHandler: (String newValue) {
          return settingsBloc.getIpFieldErrorMessage(
              value: newValue, translations: translations);
        },
        validation: (String text) {
          rangeValid =
              settingsBloc.validateIpRange(ipStart: text, ipEnd: ipEnd.text);
          return settingsBloc.validateIp(ip: text) && rangeValid;
        },
        onChanged: (String value) => ipStart.text = value,
      );

  EditableSinglelineText toField() => EditableSinglelineText(
        key: ValueKey('Setting-End-$loaded'),
        translations: translations,
        inputType: TextInputType.text,
        placeholder: '###.###.###.###',
        formatters: [
          IpInputFormatter.ipAddressInputFilter(),
          LengthLimitingTextInputFormatter(15),
          IpAddressInputFormatter()
        ],
        noCounter: true,
        maxLength: 15,
        label: translations['settingsPageIpScanRangeLabelTo'] ?? 'to',
        text: ipEnd.text,
        controller: ipEnd,
        errorMessageHandler: (String newValue) {
          return settingsBloc.getIpFieldErrorMessage(
              value: newValue, translations: translations);
        },
        validation: (String text) {
          rangeValid =
              settingsBloc.validateIpRange(ipStart: ipStart.text, ipEnd: text);
          return settingsBloc.validateIp(ip: text) && rangeValid;
        },
        onChanged: (String value) => ipEnd.text = value,
      );

  Widget body({
    required TextEditingController ipStart,
    required TextEditingController ipEnd,
    required Orientation orientation,
  }) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: (Platform.isIOS || Platform.isAndroid) &&
                            orientation == Orientation.landscape
                        ? 4.0
                        : 16.0),
                child: Text(
                  translations['settingsPageIpScanRangeHeadline'] ??
                      'IP range to scan for devices',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: ColorDefs.textColor(context: context),
                  ),
                ),
              ),
              MediaQuery.of(context).size.width > minIpFieldsInRowWidth
                  ? Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: fromField(),
                        ),
                        Flexible(
                          flex: 1,
                          child: toField(),
                        ),
                      ],
                    )
                  : Column(
                      children: [fromField(), toField()],
                    ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StreamBuilder<String>(
                      stream: ipChangeListener(ipStart),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshotStart) {
                        if (snapshotStart.hasError) {
                          return const Text('Error');
                        } else {
                          return StreamBuilder<String>(
                              stream: ipChangeListener(ipEnd),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshotEnd) {
                                if (snapshotEnd.hasError) {
                                  return const Text('Error');
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Row(
                                      children: [
                                        if (ipStart.text.isNotEmpty &&
                                            ipEnd.text.isNotEmpty &&
                                            settingsBloc.validateIp(
                                                    ip: ipStart.text) ==
                                                true &&
                                            settingsBloc.validateIp(
                                                    ip: ipEnd.text) ==
                                                true &&
                                            !settingsBloc.validateIpRange(
                                                ipStart: ipStart.text,
                                                ipEnd: ipEnd.text))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4.0),
                                            child: Text(
                                              translations[
                                                      'settingsIpRangeInvalidError'] ??
                                                  'IP-Range is invalid',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: false,
                                              style: TextStyle(
                                                color: Globals.brightness() ==
                                                        Brightness.dark
                                                    ? Colors.red.shade200
                                                    : Colors.red,
                                                fontSize: 10.0,
                                              ),
                                            ),
                                          ),
                                        IconTextButtonElement(
                                          onMacAsText: true,
                                          key: ValueKey(
                                              'Setting-Save-${snapshotStart.data}-${snapshotEnd.data}'),
                                          icon: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Icon(
                                              Icons.save,
                                              color: Colors.white,
                                              size: 20.0,
                                            ),
                                          ),
                                          label:
                                              (translations['saveButtonText'] ??
                                                      'save')
                                                  .toString()
                                                  .toFirstUpper,
                                          onPressed: ipStart.text.isNotEmpty &&
                                                  ipEnd.text.isNotEmpty &&
                                                  settingsBloc.validateIpRange(
                                                          ipStart: ipStart.text,
                                                          ipEnd: ipEnd.text) ==
                                                      true
                                              ? () async {
                                                  settingsBloc.setIpRange(
                                                      ipStart: ipStart.text,
                                                      ipEnd: ipEnd.text);
                                                  Navigator.pop(
                                                      context); // close settings page
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              });
                        }
                      }),
                ],
              ),
              SizedBox(
                  height: (Platform.isIOS || Platform.isAndroid) &&
                          orientation == Orientation.landscape
                      ? 24.0
                      : 48.0),
              Padding(
                padding: EdgeInsets.only(
                    bottom: (Platform.isIOS || Platform.isAndroid) &&
                            orientation == Orientation.landscape
                        ? 4.0
                        : 16.0),
                child: Text(
                  translations['settingsPageExtended'] ?? 'Extended Settings',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: ColorDefs.textColor(context: context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label: translations['moreInfoSelectorLabel'] ??
                      'Show buttons to display Monitoring (internal variables) and Log details',
                  enabled: moreInfo,
                  onChanged: (value) {
                    settingsBloc.setMoreInfoMode(enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  left: 16.0,
                  top: 16.0,
                  bottom: 16.0,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                      translations['zonesCoverHeadline'] ?? 'Zone Overview',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: ColorDefs.textColor(context: context),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label: translations['zonesCoverSelectorLabel'] ??
                      'Show covers of all zones',
                  enabled: coverRowActive,
                  onChanged: (value) {
                    settingsBloc.setCoverRowActiveMode(enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label:
                      '${translations['zonesArtistSelectorLabel'] ?? 'Show artist information in cover area'}',
                  enabled: coverRowArtist,
                  onChanged: (value) {
                    settingsBloc.setCoverRowArtistMode(enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label:
                      '${translations['zonesAlbumSelectorLabel'] ?? 'Show album information in cover area'}',
                  enabled: coverRowAlbum,
                  onChanged: (value) {
                    settingsBloc.setCoverRowAlbumMode(enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label:
                      '${translations['zonesTrackSelectorLabel'] ?? 'Show title information in cover area'}',
                  enabled: coverRowTrack,
                  onChanged: (value) {
                    settingsBloc.setCoverRowTrackMode(enabled: value);
                  },
                ),
              ),
              if (Globals.isDesktopDevice())
                Padding(
                  padding: const EdgeInsets.only(
                    right: 10.0,
                    bottom: 16.0,
                  ),
                  child: SwitchButton(
                    label:
                        '${translations['zonesCoverSizeSelectorLabel'] ?? 'Size of the covers dynamically in relation to the window size'}',
                    enabled: coverRowDynamicSize,
                    onChanged: (value) {
                      settingsBloc.setCoverRowDynamicSizeMode(enabled: value);
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  left: 16.0,
                  top: 16.0,
                  bottom: 16.0,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(translations['tickerHeadline'] ?? 'Ticker',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: ColorDefs.textColor(context: context),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label: translations['verticalTickerSelectorLabel'] ??
                      'Display vertical ticker if device is configured accordingly',
                  enabled: verticalTickerActive,
                  onChanged: (value) {
                    settingsBloc.setVerticalTickerActiveMode(enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label: translations['ledTickerInDeviceListSelectorLabel'] ??
                      'Display LED ticker in device list',
                  enabled: ledTickerInDeviceListActive,
                  onChanged: (value) {
                    settingsBloc.setLedTickerInDeviceListActiveMode(
                        enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label: translations['ledTickerOnTickerPageSelectorLabel'] ??
                      'Display LED ticker on the ticker page',
                  enabled: ledTickerOnTickerPageActive,
                  onChanged: (value) {
                    settingsBloc.setLedTickerOnTickerPageActiveMode(
                        enabled: value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 10.0,
                  bottom: 16.0,
                ),
                child: SwitchButton(
                  label: translations['forceTickerUpdate'] ??
                      'Update ticker immediately on text updates (interrupts running ticker)',
                  enabled: forceTickerUpdateActive,
                  onChanged: (value) {
                    settingsBloc.setForceTickerUpdateActiveMode(enabled: value);
                  },
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
            title = translations['menuEntrySettings'] ?? 'Settings';
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
                      title: Text(title),
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

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  return BlocBuilder(
                      bloc: settingsBloc,
                      builder: (context, SettingsState settingsState) {
                        if (settingsState is! SettingsStateInitial &&
                            settingsState is! SettingsStateLoaded) {
                          return Container();
                        }
                        if (kDebugMode) {
                          debugPrint('SettingsState changed => rebuild');
                        }

                        moreInfo = settingsState.moreInfo;
                        coverRowActive = settingsState.coverRowActive;
                        coverRowArtist = settingsState.coverRowArtist;
                        coverRowAlbum = settingsState.coverRowAlbum;
                        coverRowTrack = settingsState.coverRowTrack;
                        coverRowDynamicSize = settingsState.coverRowDynamicSize;
                        verticalTickerActive =
                            settingsState.verticalTickerActive;
                        ledTickerInDeviceListActive =
                            settingsState.ledTickerInDeviceListActive;
                        ledTickerOnTickerPageActive =
                            settingsState.ledTickerOnTickerPageActive;
                        forceTickerUpdateActive =
                            settingsState.forceTickerUpdateActive;

                        if (!loaded) {
                          SchedulerBinding.instance
                              .addPostFrameCallback((_) async {
                            if (mounted) {
                              setState(() {
                                ipStart.text = settingsState.ipStart;
                                ipEnd.text = settingsState.ipEnd;

                                loaded = true;
                              });
                            }
                          });
                        }

                        if (Globals.inIosStyle()) {
                          return CupertinoPageScaffold(
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
                                ipStart: ipStart,
                                ipEnd: ipEnd,
                                orientation: orientation,
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
                                  ipStart: ipStart,
                                  ipEnd: ipEnd,
                                  orientation: orientation,
                                ),
                                resizeToFullWidth: () {
                                  mainBloc
                                      .windowResizeToFullWidthAndMinimumHeight(
                                          minDesktopSize: minDesktopSize);
                                },
                              )
                            : PageWithToolbarFlutterStyle(
                                scaffoldKey: scaffoldKey,
                                title: title,
                                sliderDefaultValue: 0.0,
                                showExpandableSpeedSlider: false,
                                scrollSpeedDevice: 1.0,
                                standardDesktopSize: standardDesktopSize,
                                body: body(
                                  ipStart: ipStart,
                                  ipEnd: ipEnd,
                                  orientation: orientation,
                                ),
                                resizeToFullWidth: () {
                                  mainBloc
                                      .windowResizeToFullWidthAndMinimumHeight(
                                          minDesktopSize: minDesktopSize);
                                },
                              );
                      });
                });
              });
        });
  }
}
