import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

class TitlebarInfoContent extends StatefulWidget {
  final String ip;
  final Map<String, dynamic> translations;

  const TitlebarInfoContent({
    super.key,
    required this.ip,
    required this.translations,
  });

  @override
  State<TitlebarInfoContent> createState() => _TitlebarInfoContentState();
}

class _TitlebarInfoContentState extends State<TitlebarInfoContent> {
  String get ip => widget.ip;
  Map<String, dynamic> get translations => widget.translations;

  String macosVersion = '';

  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: mainBloc,
        builder: (context, MainState mainState) {
          if (mainState is! MainStateLoaded) {
            return SizedBox();
          }

          macosVersion = mainState.macosVersion;
          String zoneName = '';
          if (mainState.devices.isNotEmpty && mainState.info.containsKey(ip)) {
            dynamic info = mainState.info[ip];

            if (info != null && info['control_id'] != null) {
              String controlId = info['control_id'];
              if (info['channels'] != null &&
                  info['channels'][controlId] != null) {
                if (info['channels'][controlId] == 'webserver' ||
                    info['channels'][controlId] == 'spotifyconnect') {
                  zoneName = controlId;
                } else {
                  zoneName = info['channels'][controlId];
                }
              }
            }

            return Container(
              constraints: BoxConstraints(minWidth: 350.0),
              child: Text(
                'IP: $ip  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName\n${translations['deviceListTime'] ?? 'time'}: ${mainRepository.getFormattedDateString(date: info['time'])}  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ',
                style: TextStyle(
                  color:
                      SharedWidgets.inMacosStyle() || SharedWidgets.inIosStyle()
                          ? SharedWidgets.textColor(context: context)
                          : Colors.white,
                  fontSize: 12.0,
                ),
              ),
            );
          }

          return Text('');
        });
  }
}
