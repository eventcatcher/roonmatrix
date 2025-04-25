import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder, BlocProvider;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart'
    show MainState, MainStateLoaded;

class CoverPage extends StatefulWidget {
  final int index;
  final String name;
  final Map<String, dynamic> selectedZone;
  final Map<String, dynamic> translations;

  const CoverPage({
    super.key,
    required this.index,
    required this.name,
    required this.selectedZone,
    required this.translations,
  });

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage> {
  int get index => widget.index;
  String get name => widget.name;
  Map<String, dynamic> get translations => widget.translations;

  double fontSize =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux ? 20.0 : 16.0;

  late MainBloc mainBloc;
  late Map<String, dynamic> selectedZone;

  @override
  void initState() {
    selectedZone = widget.selectedZone;
    mainBloc = BlocProvider.of<MainBloc>(context);

    super.initState();
  }

  Widget body() => SizedBox(
        child: RoonmatrixAnimatedGradient(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocBuilder(
                  bloc: mainBloc,
                  builder: (context, MainState mainState) {
                    if (mainState is MainStateLoaded) {
                      Map<String, dynamic> selectedZoneUpdated = mainState
                          .info[mainState.devices[index]]?['selected_zone'];

                      if (selectedZoneUpdated != selectedZone) {
                        SchedulerBinding.instance
                            .addPostFrameCallback((_) async {
                          if (mounted) {
                            setState(() {
                              selectedZone = selectedZoneUpdated;
                            });
                          }
                        });
                      }
                    }

                    return const SizedBox(height: 0.0);
                  }),
              Expanded(
                child: OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  return NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (notification) {
                      build(context);
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: Container(
                        padding: EdgeInsets.all(24.0),
                        child: selectedZone['image_url'] != null &&
                                (selectedZone['image_url'] as String).isNotEmpty
                            ? Image.network(selectedZone['image_url'],
                                fit: BoxFit.contain)
                            : SvgPicture.asset(
                                'assets/svg/8-8-led-matrix-display-unit.svg',
                                allowDrawingOutsideViewBox: false,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                    ),
                  );
                }),
              ),
              if (selectedZone.isNotEmpty && selectedZone['artist'] != null)
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0),
                      child: Table(
                        columnWidths: {
                          0: IntrinsicColumnWidth(),
                          1: IntrinsicColumnWidth()
                        },
                        children: [
                          TableRow(children: [
                            Column(children: [
                              Container(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${translations['coverZoneHeader'] ?? 'Zone'}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                            Column(children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  selectedZone['zone'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                          ]),
                          TableRow(children: [
                            Column(children: [
                              Container(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${translations['coverArtistHeader'] ?? 'Artist'}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                            Column(children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  selectedZone['artist'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                          ]),
                          TableRow(children: [
                            Column(children: [
                              Container(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${translations['coverAlbumHeader'] ?? 'Album'}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                            Column(children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  selectedZone['album'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                          ]),
                          TableRow(children: [
                            Column(children: [
                              Container(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${translations['coverTrackHeader'] ?? 'Track'}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                            Column(children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  selectedZone['track'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                              )
                            ]),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (SharedWidgets.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          child: SafeArea(
            child: body(),
          ),
        ),
      );
    }

    return SharedWidgets.inMacosStyle()
        ? Material(
            child: MacosScaffold(
              toolBar: ToolBar(
                title: Text(name),
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
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(name),
            ),
            body: body(),
          );
  }
}
