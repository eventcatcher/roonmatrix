import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/helper/ip_address_input_formatter.dart';
import 'package:roonmatrix/ui/helper/ip_input_formatter.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
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

  Widget body() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        translations['settingsPageIpScanRangeHeadline'] ??
                            'IP range to scan for devices',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: SharedWidgets.textColor(
                              showMacStyle: showMacStyle, context: context),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: EditableSinglelineText(
                                    showMacStyle: showMacStyle,
                                    key: ValueKey('Start-$rangeValid'),
                                    inputType: TextInputType.text,
                                    placeholder: '###.###.###.###',
                                    formatters: [
                                      IpInputFormatter.ipAddressInputFilter(),
                                      LengthLimitingTextInputFormatter(15),
                                      IpAddressInputFormatter()
                                    ],
                                    noCounter: true,
                                    maxLength: 15,
                                    label: translations[
                                            'settingsPageIpScanRangeLabelFrom'] ??
                                        'from',
                                    text: ipStart.text,
                                    errorMessageHandler: (String newValue) {
                                      return settingsBloc
                                          .getIpFieldErrorMessage(
                                              value: newValue,
                                              translations: translations);
                                    },
                                    validation: (String text) {
                                      rangeValid = settingsBloc.validateIpRange(
                                          ipStart: text, ipEnd: ipEnd.text);
                                      return settingsBloc.validateIp(
                                              ip: text) &&
                                          rangeValid;
                                    },
                                    onChanged: (String value) =>
                                        settingsBloc.setIpRange(
                                            ipStart: value, ipEnd: ipEnd.text),
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: EditableSinglelineText(
                                    showMacStyle: showMacStyle,
                                    key: ValueKey('End-$rangeValid'),
                                    inputType: TextInputType.text,
                                    placeholder: '###.###.###.###',
                                    formatters: [
                                      IpInputFormatter.ipAddressInputFilter(),
                                      LengthLimitingTextInputFormatter(15),
                                      IpAddressInputFormatter()
                                    ],
                                    noCounter: true,
                                    maxLength: 15,
                                    label: translations[
                                            'settingsPageIpScanRangeLabelTo'] ??
                                        'to',
                                    text: ipEnd.text,
                                    errorMessageHandler: (String newValue) {
                                      return settingsBloc
                                          .getIpFieldErrorMessage(
                                              value: newValue,
                                              translations: translations);
                                    },
                                    validation: (String text) {
                                      rangeValid = settingsBloc.validateIpRange(
                                          ipStart: ipStart.text, ipEnd: text);
                                      return settingsBloc.validateIp(
                                              ip: text) &&
                                          rangeValid;
                                    },
                                    onChanged: (String value) =>
                                        settingsBloc.setIpRange(
                                            ipStart: ipStart.text,
                                            ipEnd: value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
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

                ipStart.text = settingsState.ipStart;
                ipEnd.text = settingsState.ipEnd;

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
                                  child: body(),
                                ),
                              );
                            }),
                          ),
                        ],
                      )
                    : DefaultTabController(
                        length: 2,
                        child: Scaffold(
                          appBar: AppBar(
                            title: Text(title),
                            actions: const [],
                          ),
                          body: body(),
                        ),
                      );
              });
        });
  }
}
