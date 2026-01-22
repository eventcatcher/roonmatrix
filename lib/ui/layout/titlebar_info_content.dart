import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
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

  final double minWidth = 350.0;
  final double fontSize = 12.0;

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

          String zoneName = '';
          if (mainState.devices.isNotEmpty && mainState.info.containsKey(ip)) {
            Map<String, dynamic> info = mainState.info[ip];
            zoneName = mainRepository.getZoneName(info: info);

            return Container(
              constraints: BoxConstraints(minWidth: minWidth),
              child: Text(
                mainRepository.getTimeZonePlaycountText(
                    translations: translations,
                    info: info,
                    zoneName: zoneName,
                    ip: ip,
                    withLineBreak: true),
                style: TextStyle(
                  color: Globals.inMacosStyle() || Globals.inIosStyle()
                      ? ColorDefs.textColor(context: context)
                      : Colors.white,
                  fontSize: fontSize,
                ),
              ),
            );
          }

          return SizedBox();
        });
  }
}
