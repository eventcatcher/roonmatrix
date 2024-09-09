import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/helper/ip_address_input_formatter.dart';
import 'package:roonmatrix/ui/helper/ip_input_formatter.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';

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

  late SettingsBloc settingsBloc;
  TextEditingController ipStart = TextEditingController();
  TextEditingController ipEnd = TextEditingController();

  @override
  void initState() {
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    ipStart.text = '';
    ipEnd.text = '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                title: const Text('Settings'),
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
                              const Text(
                                'IP range',
                                style: TextStyle(fontSize: 18.0),
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
                                            inputType: TextInputType.text,
                                            placeholder: '###.###.###.###',
                                            formatters: [
                                              IpInputFormatter
                                                  .ipAddressInputFilter(),
                                              LengthLimitingTextInputFormatter(
                                                  15),
                                              IpAddressInputFormatter()
                                            ],
                                            noCounter: true,
                                            maxLength: 15,
                                            label: 'from',
                                            labelColor: Colors.red,
                                            borderColor: Colors.red.shade300,
                                            text: ipStart.text,
                                            errorMessageHandler:
                                                (String newValue) {
                                              if (newValue.isEmpty) {
                                                return 'IP-Feld darf nicht leer sein';
                                              }

                                              return 'IP hat ein ungültiges Format';
                                            },
                                            validation: (String text) =>
                                                settingsBloc.validateIp(
                                                    ip: text),
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
                                            placeholder: '###.###.###.###',
                                            formatters: [
                                              IpInputFormatter
                                                  .ipAddressInputFilter(),
                                              LengthLimitingTextInputFormatter(
                                                  15),
                                              IpAddressInputFormatter()
                                            ],
                                            noCounter: true,
                                            maxLength: 15,
                                            label: 'to',
                                            labelColor: Colors.red,
                                            borderColor: Colors.red.shade300,
                                            text: ipEnd.text,
                                            errorMessageHandler:
                                                (String newValue) {
                                              if (newValue.isEmpty) {
                                                return 'IP-Feld darf nicht leer sein';
                                              }

                                              if (!settingsBloc.validateIp(
                                                  ip: newValue)) {
                                                return 'IP hat ein ungültiges Format';
                                              }

                                              return 'Die IP-Range ist ungültig';
                                            },
                                            validation: (String text) =>
                                                settingsBloc.validateIp(
                                                    ip: text) &&
                                                settingsBloc.validateIpRange(
                                                    ipStart: ipStart.text,
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
  }
}
