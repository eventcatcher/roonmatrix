import 'dart:io';

import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/select_box_with_icon.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';

class LogPage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const LogPage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<LogPage> createState() => LogPageState();
}

class LogPageState extends State<LogPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;
  int hours = 1;
  bool saveIdle = false;

  late TranslationsBloc translationsBloc;
  late OptionsBloc optionsBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    optionsBloc.getLog(ip: ip, hours: hours);

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
              bloc: optionsBloc,
              builder: (context, OptionsState optionsState) {
                if (optionsState is! OptionsStateLoaded) {
                  return Container();
                }

                String search = optionsState.searchFilter['log']!;
                String log = optionsState.log;
                if (log.isNotEmpty) {
                  if (log.endsWith('"')) {
                    log = log.substring(0, log.length - 1);
                  }
                  if (log.startsWith('"')) {
                    log = log.substring(1);
                  }
                  log = log.replaceAll('\\n', '\n');
                  if (search.isNotEmpty) {
                    log = log.replaceAll(
                        RegExp(search, caseSensitive: false), '<b>$search</b>');
                  }
                }

                return DefaultTabController(
                  length: 2,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                          '$name :  ${translations['logPageHeaderText'] ?? 'Log'}'),
                      actions: const [],
                    ),
                    body: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SearchField(
                            type: 'log',
                            controller:
                                optionsBloc.getSearchController(type: 'log'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 0.0),
                          child: SelectBoxWithIcon(
                            options: translationsBloc.state.logHoursOptions,
                            placeholder:
                                translations['pleaseSelectPlaceholder'] ??
                                    'Please Select',
                            labelColor: Colors.black,
                            selected: hours.toString(),
                            onChanged: (String? value) {
                              if (mounted && value != null) {
                                setState(() => hours = int.parse(value));
                                optionsBloc.getLog(ip: ip, hours: hours);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: optionsState.idle == true
                              ? const LoadingIndicatorSmall()
                              : ListView(
                                  shrinkWrap: true,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: StyledText(
                                        text: log,
                                        tags: {
                                          'b': StyledTextTag(
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        },
                                      ),
                                    ),
                                  ],
                                ),
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
                                label: Text(translations['exportButtonText'] ??
                                    'export'),
                                onPressed: saveIdle == true ||
                                        optionsState.idle == true
                                    ? null
                                    : () async {
                                        setState(() {
                                          saveIdle = true;
                                        });
                                        bool? valid =
                                            await optionsBloc.exportData(
                                                name: name,
                                                ip: ip,
                                                type: 'log');
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
  }
}
