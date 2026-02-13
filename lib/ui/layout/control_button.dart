import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';

class ControlButton extends StatelessWidget {
  final double buttonSize;
  final double? horizontalMargin;
  final double verticalTooltipOffset;
  final String tooltipText;
  final Icon icon;
  final Color? color;
  final bool readOnly;
  final VoidCallback onPressed;

  const ControlButton({
    super.key,
    required this.buttonSize,
    this.horizontalMargin,
    required this.verticalTooltipOffset,
    required this.tooltipText,
    required this.icon,
    this.color,
    required this.readOnly,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      margin: horizontalMargin != null
          ? EdgeInsets.symmetric(horizontal: horizontalMargin!)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Tooltip(
          message: readOnly ? '' : tooltipText,
          triggerMode: TooltipTriggerMode.manual,
          waitDuration: Duration(seconds: 3),
          verticalOffset: verticalTooltipOffset,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              padding: EdgeInsets.zero,
              color: color,
              hoverColor:
                  readOnly ? Colors.transparent : Globals.hoverButtonBackground,
              onPressed: readOnly ? null : () => onPressed(),
              icon: icon,
              iconSize: buttonSize * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
