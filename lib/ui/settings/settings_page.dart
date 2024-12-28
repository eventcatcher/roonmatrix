import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/helper/ip_address_input_formatter.dart';
import 'package:roonmatrix/ui/helper/ip_input_formatter.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class SettingsPage extends StatefulWidget {
  final bool showMacStyle;
  final VoidCallback close;

  const SettingsPage({
    super.key,
    required this.showMacStyle,
    required this.close,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool get showMacStyle => widget.showMacStyle;
  VoidCallback get close => widget.close;

  Map<String, dynamic> translations = {};
  TextEditingController ipStart = TextEditingController();
  TextEditingController ipEnd = TextEditingController();
  String title = '';
  bool translationsLoaded = false;
  bool rangeValid = false;
  bool loaded = false;

  late TranslationsBloc translationsBloc;
  late SettingsBloc settingsBloc;

  @override
  void initState() {
    title = 'Settings';
    ipStart.text = '';
    ipEnd.text = '';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);

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
        showMacStyle: showMacStyle,
        key: ValueKey('Start-$loaded}'),
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
        showMacStyle: showMacStyle,
        key: ValueKey('End-$loaded'),
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
  }) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  translations['settingsPageIpScanRangeHeadline'] ??
                      'IP range to scan for devices',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: SharedWidgets.textColor(
                        showMacStyle: showMacStyle, context: context),
                  ),
                ),
              ),
              MediaQuery.of(context).size.width > 400
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
              SizedBox(height: 32.0),
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
                                  return Row(
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
                                          padding:
                                              const EdgeInsets.only(right: 4.0),
                                          child: Text(
                                            translations[
                                                    'settingsIpRangeInvalidError'] ??
                                                'IP-Range is invalid',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: TextStyle(
                                              color:
                                                  SharedWidgets.brightness() ==
                                                          Brightness.dark
                                                      ? Colors.red.shade200
                                                      : Colors.red,
                                              fontSize: 10.0,
                                            ),
                                          ),
                                        ),
                                      IconTextButtonElement(
                                        key: ValueKey(
                                            'save-${snapshotStart.data}-${snapshotEnd.data}'),
                                        showMacStyle: showMacStyle,
                                        icon: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Icon(
                                            Icons.save,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ),
                                        label: translations['saveButtonText'] ??
                                            'save',
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
                                  );
                                }
                              });
                        }
                      }),
                ],
              )
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
            return showMacStyle == true && Platform.isMacOS
                ? MacosScaffold(
                    toolBar: ToolBar(
                      title: Text(title),
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
              bloc: settingsBloc,
              builder: (context, SettingsState settingsState) {
                if (settingsState is! SettingsStateInitial &&
                    settingsState is! SettingsStateLoaded) {
                  return Container();
                }
                if (kDebugMode) {
                  print('state changed => rebuild');
                }

                if (!loaded) {
                  SchedulerBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      setState(() {
                        ipStart.text = settingsState.ipStart;
                        ipEnd.text = settingsState.ipEnd;

                        loaded = true;
                      });
                    }
                  });
                }

                if (Platform.isIOS) {
                  return CupertinoPageScaffold(
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
                        ipStart: ipStart,
                        ipEnd: ipEnd,
                      ),
                    ),
                  );
                }

                return showMacStyle == true && Platform.isMacOS
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
                                    ipStart: ipStart,
                                    ipEnd: ipEnd,
                                  ),
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
                        body: body(
                          ipStart: ipStart,
                          ipEnd: ipEnd,
                        ),
                      );
              });
        });
  }
}
