import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/switch_element.dart';

class SwitchButton extends StatelessWidget {
  final String? label;
  final String? aligned;
  final Color? labelColor;
  final bool reverse;
  final bool enabled;
  final void Function(bool value) onChanged;

  const SwitchButton({
    super.key,
    this.label,
    this.aligned,
    this.labelColor = Colors.black,
    this.reverse = false,
    this.enabled = false,
    required this.onChanged,
  });

  final double labelFontSize = 12.0;
  final Color iosActiveTrackColor = const Color.fromARGB(255, 20, 106, 237);

  Widget labelWidget(context) => Expanded(
        child: label != null
            ? Text(
                label!,
                style: TextStyle(
                  color: SharedWidgets.brightness() == Brightness.dark
                      ? SharedWidgets.textColor(context: context)
                      : labelColor ?? SharedWidgets.textColor(context: context),
                  fontSize: labelFontSize,
                ),
              )
            : Container(),
      );

  Widget switchWidget({bool noSpace = true}) => Container(
        transform: noSpace ? Matrix4.translationValues(10.0, -0.0, 0.0) : null,
        child: SwitchElement(
          materialTapTargetSize: SharedWidgets.inIosStyle()
              ? null
              : MaterialTapTargetSize.shrinkWrap,
          value: enabled,
          onChanged: (bool value) {
            onChanged(value);
          },
          activeTrackColor:
              SharedWidgets.inIosStyle() ? null : iosActiveTrackColor,
          activeColor: SharedWidgets.inIosStyle() ? null : Colors.white,
        ),
      );

  EdgeInsets getMargin() {
    EdgeInsets margin = EdgeInsets.zero;

    switch (aligned) {
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

    return margin;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: getMargin(),
      alignment: Alignment.topLeft,
      transform: reverse ? Matrix4.translationValues(-9.0, -0.0, 0.0) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          reverse ? switchWidget(noSpace: false) : labelWidget(context),
          reverse
              ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: labelWidget(context),
                )
              : switchWidget(),
        ],
      ),
    );
  }
}
