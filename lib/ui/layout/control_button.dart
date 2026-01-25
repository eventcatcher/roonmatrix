import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';

class ControlButton extends StatelessWidget {
  final double buttonSize;
  final double verticalOffset;
  final String tooltipText;
  final Icon icon;
  final Color? color;
  final bool readOnly;
  final VoidCallback onPressed;

  const ControlButton({
    super.key,
    required this.buttonSize,
    required this.verticalOffset,
    required this.tooltipText,
    required this.icon,
    this.color,
    required this.readOnly,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Tooltip(
        message: readOnly ? '' : tooltipText,
        triggerMode: TooltipTriggerMode.manual,
        waitDuration: Duration(seconds: 3),
        verticalOffset: verticalOffset,
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            padding: EdgeInsets.zero,
            color: color,
            hoverColor:
                readOnly ? Colors.transparent : Globals.hoverButtonBackground,
            onPressed: readOnly ? null : () => onPressed(),
            icon: icon,
          ),
        ),
      ),
    );
  }
}
