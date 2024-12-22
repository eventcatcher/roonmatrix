import 'package:flutter/material.dart';
import 'package:roonmatrix/main.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/switch_element.dart';

class SwitchButton extends StatefulWidget {
  final bool showMacStyle;
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final bool reverse;
  final bool enabled;
  final void Function(bool value) onChanged;

  const SwitchButton({
    super.key,
    required this.showMacStyle,
    this.aligned,
    this.label,
    this.labelColor = Colors.black,
    this.reverse = false,
    this.enabled = false,
    required this.onChanged,
  });

  @override
  SwitchButtonState createState() => SwitchButtonState();
}

class SwitchButtonState extends State<SwitchButton> {
  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    switch (widget.aligned) {
      case "left":
        margin = const EdgeInsets.only(left: 16.0, right: 8.0);
        break;
      case "right":
        margin = const EdgeInsets.only(left: 8.0, right: 16.0);
        break;
      case "inline":
        margin = const EdgeInsets.all(0);
        break;
      default:
        margin = const EdgeInsets.only(left: 16.0, right: 16.0);
    }
    super.initState();
  }

  Widget labelWidget() => Expanded(
        child: widget.label != null
            ? Text(
                widget.label!,
                style: TextStyle(
                  color: SharedWidgets.brightness() == Brightness.dark
                      ? SharedWidgets.textColor(
                          showMacStyle: widget.showMacStyle, context: context)
                      : widget.labelColor ??
                          SharedWidgets.textColor(
                              showMacStyle: widget.showMacStyle,
                              context: context),
                  fontSize: 12.0,
                ),
              )
            : Container(),
      );

  Widget switchWidget({bool noSpace = true}) => Container(
        transform: noSpace ? Matrix4.translationValues(10.0, -0.0, 0.0) : null,
        child: SwitchElement(
          showMacStyle: showMacStyle,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: widget.enabled,
          onChanged: (bool value) {
            widget.onChanged(value);
          },
          activeTrackColor: const Color.fromARGB(255, 20, 106, 237),
          activeColor: Colors.white,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: Alignment.topLeft,
      transform:
          widget.reverse ? Matrix4.translationValues(-9.0, -0.0, 0.0) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.reverse ? switchWidget(noSpace: false) : labelWidget(),
          widget.reverse ? labelWidget() : switchWidget(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
