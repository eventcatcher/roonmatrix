import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
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

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);

    super.initState();
  }

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
            width: widget.noDevicesFoundRectSize,
            height: widget.noDevicesFoundRectSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.deepOrange,
                width: 5.0,
              ),
              borderRadius: BorderRadius.all(
                  Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withValues(alpha: 0.15),
                  spreadRadius: 0,
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                translations['scanNoFoundMessage'] ?? 'no devices found',
                style: TextStyle(
                  color: SharedWidgets.textColor(context: context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
