import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/helper/ip_address_input_formatter.dart';
import 'package:roonmatrix/ui/helper/ip_input_formatter.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback close;

  const SettingsPage({
    super.key,
    required this.close,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  VoidCallback get close => widget.close;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;
  TextEditingController ipStart = TextEditingController();
  TextEditingController ipEnd = TextEditingController();

  late TranslationsBloc translationsBloc;
  late SettingsBloc settingsBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    ipStart.text = '';
    ipEnd.text = '';

    super.initState();
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
            return const SizedBox();
          }

          return BlocBuilder(
              bloc: settingsBloc,
              builder: (context, SettingsState settingsState) {
                if (settingsState is! SettingsStateInitial &&
                    settingsState is! SettingsStateLoaded) {
                  return Container();
                }
                debugPrint('uuu state changed => rebuild');

                ipStart.text = settingsState.ipStart;
                ipEnd.text = settingsState.ipEnd;

                return DefaultTabController(
                  length: 2,
                  child: Scaffold(
                    appBar: AppBar(
                      title:
                          Text(translations['menuEntrySettings'] ?? 'Settings'),
                      actions: const [],
                    ),
                    body: SingleChildScrollView(
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
                                      translations[
                                              'settingsPageIpScanRangeHeadline'] ??
                                          'IP range to scan for devices',
                                      style: const TextStyle(fontSize: 18.0),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                flex: 1,
                                                child: EditableSinglelineText(
                                                  inputType: TextInputType.text,
                                                  placeholder:
                                                      '###.###.###.###',
                                                  formatters: [
                                                    IpInputFormatter
                                                        .ipAddressInputFilter(),
                                                    LengthLimitingTextInputFormatter(
                                                        15),
                                                    IpAddressInputFormatter()
                                                  ],
                                                  noCounter: true,
                                                  maxLength: 15,
                                                  label: translations[
                                                          'settingsPageIpScanRangeLabelFrom'] ??
                                                      'from',
                                                  labelColor: Colors.red,
                                                  borderColor:
                                                      Colors.red.shade300,
                                                  text: ipStart.text,
                                                  errorMessageHandler:
                                                      (String newValue) {
                                                    if (newValue.isEmpty) {
                                                      return translations[
                                                              'settingsIpFieldEmptyError'] ??
                                                          'IP field cannot be empty';
                                                    }

                                                    if (!settingsBloc
                                                        .validateIp(
                                                            ip: newValue)) {
                                                      return translations[
                                                              'settingsIpFieldInvalidError'] ??
                                                          'IP is invalid';
                                                    }

                                                    return translations[
                                                            'settingsIpRangeInvalidError'] ??
                                                        'IP-Range is invalid';
                                                  },
                                                  validation: (String text) =>
                                                      settingsBloc.validateIp(
                                                          ip: text) &&
                                                      settingsBloc
                                                          .validateIpRange(
                                                              ipStart: text,
                                                              ipEnd:
                                                                  ipEnd.text),
                                                  onChanged: (String value) =>
                                                      settingsBloc.setIpRange(
                                                          ipStart: value,
                                                          ipEnd: ipEnd.text),
                                                ),
                                              ),
                                              Flexible(
                                                flex: 1,
                                                child: EditableSinglelineText(
                                                  inputType: TextInputType.text,
                                                  placeholder:
                                                      '###.###.###.###',
                                                  formatters: [
                                                    IpInputFormatter
                                                        .ipAddressInputFilter(),
                                                    LengthLimitingTextInputFormatter(
                                                        15),
                                                    IpAddressInputFormatter()
                                                  ],
                                                  noCounter: true,
                                                  maxLength: 15,
                                                  label: translations[
                                                          'settingsPageIpScanRangeLabelTo'] ??
                                                      'to',
                                                  labelColor: Colors.red,
                                                  borderColor:
                                                      Colors.red.shade300,
                                                  text: ipEnd.text,
                                                  errorMessageHandler:
                                                      (String newValue) {
                                                    if (newValue.isEmpty) {
                                                      return translations[
                                                              'settingsIpFieldEmptyError'] ??
                                                          'IP field cannot be empty';
                                                    }

                                                    if (!settingsBloc
                                                        .validateIp(
                                                            ip: newValue)) {
                                                      return translations[
                                                              'settingsIpFieldInvalidError'] ??
                                                          'IP is invalid';
                                                    }

                                                    return translations[
                                                            'settingsIpRangeInvalidError'] ??
                                                        'IP-Range is invalid';
                                                  },
                                                  validation: (String text) =>
                                                      settingsBloc.validateIp(
                                                          ip: text) &&
                                                      settingsBloc
                                                          .validateIpRange(
                                                              ipStart:
                                                                  ipStart.text,
                                                              ipEnd: text),
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
                    ),
                  ),
                );
              });
        });
  }
}
