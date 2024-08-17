import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';

class InfoPage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const InfoPage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<InfoPage> createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  bool saveIdle = false;

  late OptionsBloc optionsBloc;

  @override
  void initState() {
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    optionsBloc.getInfo(ip: ip);

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

          String search = optionsState.searchFilter['info']!;
          Map<String, dynamic> info =
              Map.from((optionsState.info[ip] ?? {}) as Map<String, dynamic>);
          if (search.isNotEmpty) {
            info.removeWhere((key, value) =>
                !key.toLowerCase().contains(search.toLowerCase()));
          }

          String infoStr = info
              .map((k, v) {
                return MapEntry(k, '$k: $v');
              })
              .values
              .toList()
              .join('\n');

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text('$name : Info'),
                actions: const [],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SearchField(
                      type: 'info',
                      controller: optionsBloc.getSearchController(type: 'info'),
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
                                child: Text(infoStr),
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
                                      name: name, ip: ip, type: 'info');
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
