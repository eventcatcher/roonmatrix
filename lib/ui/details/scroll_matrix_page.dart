import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:window_manager/window_manager.dart';

class ScrollMatrixPage extends StatefulWidget {
  final int index;
  final String name;
  final Map<String, dynamic> translations;
  final VoidCallback close;

  const ScrollMatrixPage({
    super.key,
    required this.index,
    required this.name,
    required this.translations,
    required this.close,
  });

  @override
  State<ScrollMatrixPage> createState() => _ScrollMatrixPageState();
}

class _ScrollMatrixPageState extends State<ScrollMatrixPage> {
  int get index => widget.index;
  String get name => widget.name;
  Map<String, dynamic> get translations => widget.translations;
  VoidCallback get close => widget.close;

  String displaystr = '';

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowResize();
    }

    super.initState();
  }

  windowResize() async {
    Size? screenSize = mainBloc.getScreenSize();
    Size newSize = Size(screenSize?.width ?? 1280, 276);

    await windowManager.setPosition(Offset.zero);
    windowManager.setSize(newSize, animate: true);
  }

  getMaskedString(String str) {
    int strTimePos = str.indexOf('Uhrzeit');
    if (strTimePos == -1) {
      return str;
    }

    String strMasked =
        '${str.substring(0, strTimePos + 9)}hh:mm:ss${str.substring(strTimePos + 17)}';
    return strMasked;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double fontSize = Platform.isMacOS || Platform.isWindows || Platform.isLinux
        ? height - 60 - height / 6
        : 24;

    // if (kDebugMode) {
    //   print('height: $height, fontSize: $fontSize');
    // }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          Row(
            children: [
              BlocBuilder(
                  bloc: mainBloc,
                  builder: (context, MainState mainState) {
                    String zoneName = '';
                    dynamic info = mainState.info[mainState.devices[index]];
                    if (info['control_id'] != null) {
                      String controlId = info['control_id'];
                      if (info['channels'] != null &&
                          info['channels'][controlId] != null) {
                        if (info['channels'][controlId] == 'webserver') {
                          zoneName = controlId;
                        } else {
                          zoneName = info['channels'][controlId];
                        }
                      }
                    }

                    return Text(
                        'IP: ${mainState.devices[index]}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ');
                  })
            ],
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is MainStateLoaded) {
                  String displaystrNew =
                      mainState.info[mainState.devices[index]]['displaystr'];

                  String displaystrNewMasked = getMaskedString(displaystrNew);
                  String displaystrMasked = getMaskedString(displaystr);

                  if (displaystrNewMasked != displaystrMasked) {
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        setState(() {
                          displaystr = displaystrNew;
                        });
                      }
                    });
                  }
                }

                return const SizedBox(height: 0.0);
              }),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              SizedBox(
                height: fontSize * 1.15,
                child: TextScroll(
                  '$displaystr    ////    ',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: fontSize,
                  ),
                  mode: TextScrollMode.endless,
                  velocity: Velocity(
                      pixelsPerSecond: Offset(200 + fontSize / 2.25, 0)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
