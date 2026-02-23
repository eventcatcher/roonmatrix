import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class DevicesReloadButton extends StatefulWidget {
  final Map<String, dynamic> translations;
  final double noDevicesFoundRectSize;

  const DevicesReloadButton({
    super.key,
    required this.translations,
    this.noDevicesFoundRectSize = 184,
  });

  @override
  State<DevicesReloadButton> createState() => DevicesReloadButtonState();
}

class DevicesReloadButtonState extends State<DevicesReloadButton> {
  Map<String, dynamic> get translations => widget.translations;
  double get noDevicesFoundRectSize => widget.noDevicesFoundRectSize;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);

    super.initState();
  }

  Color borderColor({required double alpha}) =>
      Colors.deepOrange.withValues(alpha: alpha);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            mainBloc.getSearchController(type: 'main').clear();
            mainBloc.setSearchFilter(type: 'main', filter: '');
            mainBloc.searching(idle: true);
          },
          child: Container(
            width: noDevicesFoundRectSize,
            height: noDevicesFoundRectSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor(alpha: 1.0),
                width: 5.0,
              ),
              borderRadius: Globals.borderRadius(),
              boxShadow: [
                BoxShadow(
                  color: borderColor(alpha: 0.15),
                  spreadRadius: 0,
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: noDevicesFoundRectSize / 2 - 19 - 12,
                    child: Text(
                      '${translations['scanNoFoundMessage'] ?? 'no devices found'}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorDefs.textColor(context: context),
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.refresh,
                    color: ColorDefs.blueIconColor(context: context),
                    size: 36.0,
                  ),
                  Container(
                    alignment: Alignment.center,
                    height: noDevicesFoundRectSize / 2 - 19 - 12,
                    child: Text(
                      '${translations['clickToScanAgainMessage'] ?? 'Click here to scan again'}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorDefs.textColor(context: context),
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
