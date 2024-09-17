import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

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

  Map<String, dynamic> translations = {};
  String title = '';
  bool translationsLoaded = false;
  bool saveIdle = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : Info';
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);

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
            title = '$name : ${translations['infoPageHeaderText'] ?? 'Info'}';
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(title),
                ),
                body: const SizedBox());
          }

          return BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return Container();
                }

                String search = mainState.searchFilter['info']!;
                Map<String, dynamic> info = Map.from(
                    (mainState.info[ip] ?? {}) as Map<String, dynamic>);
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
                      title: Text(title),
                      actions: const [],
                    ),
                    body: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SearchField(
                            type: 'info',
                            controller:
                                mainBloc.getSearchController(type: 'info'),
                          ),
                        ),
                        Expanded(
                          child: mainState.subPageIdle == true
                              ? const LoadingIndicatorSmall()
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
                                label: Text(translations['exportButtonText'] ??
                                    'export'),
                                onPressed: saveIdle == true ||
                                        mainState.subPageIdle == true
                                    ? null
                                    : () async {
                                        setState(() {
                                          saveIdle = true;
                                        });
                                        bool? valid = await mainBloc.exportData(
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
