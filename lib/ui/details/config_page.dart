import 'dart:io';

import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';

class ConfigPage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const ConfigPage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<ConfigPage> createState() => ConfigPageState();
}

class ConfigPageState extends State<ConfigPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  bool saveIdle = false;

  late OptionsBloc optionsBloc;

  @override
  void initState() {
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    optionsBloc.getConfig(ip: ip);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: optionsBloc,
        builder: (context, OptionsState optionsState) {
          if (optionsState is! OptionsStateLoaded) {
            return Container();
          }

          String search = optionsState.searchFilter['config']!;
          String jsonStr = optionsBloc.getPrettyJSONString(optionsState.config);
          if (search.isNotEmpty) {
            jsonStr = jsonStr.replaceAll(
                RegExp(search, caseSensitive: false), '<b>$search</b>');
          }

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text('$name : Config'),
                actions: const [],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SearchField(
                      type: 'config',
                      controller:
                          optionsBloc.getSearchController(type: 'config'),
                    ),
                  ),
                  Expanded(
                    child: optionsState.idle == true
                        ? const LoadingIndicator()
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: StyledText(
                                  text: jsonStr,
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
                          label: const Text('export'),
                          onPressed: saveIdle == true ||
                                  optionsState.idle == true
                              ? null
                              : () async {
                                  setState(() {
                                    saveIdle = true;
                                  });
                                  bool? valid = await optionsBloc.exportData(
                                      name: name, ip: ip, type: 'config');
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
                                        content:
                                            Text("export successfully done"),
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
                      ],
                    ),
                  ),
                  if (Platform.isIOS) const SizedBox(height: 14.0),
                ],
              ),
            ),
          );
        });
  }
}
