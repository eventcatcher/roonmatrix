import 'package:flutter/material.dart';

class SwitchButton extends StatefulWidget {
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final bool reverse;
  final bool enabled;
  final void Function(bool value) onChanged;

  const SwitchButton({
    super.key,
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
                  color: widget.labelColor,
                  fontSize: 12.0,
                ),
              )
            : Container(),
      );

  Widget switchWidget({bool noSpace = true}) => Container(
        transform: noSpace ? Matrix4.translationValues(10.0, -0.0, 0.0) : null,
        child: Switch(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: widget.enabled,
          onChanged: (bool value) {
            widget.onChanged(value);
          },
          activeTrackColor: const Color.fromARGB(255, 13, 71, 161),
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
