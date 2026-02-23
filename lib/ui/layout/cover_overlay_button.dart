import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';

class CoverOverlayButton extends StatefulWidget {
  final Alignment alignment;
  final double coverWidth;
  final bool additionalVisibility;
  final Icon icon;
  final String message;
  final VoidCallback onPressed;

  const CoverOverlayButton({
    super.key,
    required this.alignment,
    required this.coverWidth,
    this.additionalVisibility = false,
    required this.icon,
    required this.message,
    required this.onPressed,
  });

  @override
  State<CoverOverlayButton> createState() => _CoverOverlayButtonState();
}

class _CoverOverlayButtonState extends State<CoverOverlayButton> {
  Alignment get alignment => widget.alignment;
  double get coverWidth => widget.coverWidth;
  bool get additionalVisibility => widget.additionalVisibility;
  Icon get icon => widget.icon;
  String get message => widget.message;
  VoidCallback get onPressed => widget.onPressed;

  final Duration opacityDuration = const Duration(milliseconds: 200);
  final Color iconColor = Colors.blue.shade900;

  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: MouseRegion(
        onEnter: (_) =>
            Globals.isDesktopDevice() ? setState(() => hovered = true) : null,
        onExit: (_) =>
            Globals.isDesktopDevice() ? setState(() => hovered = false) : null,
        child: AnimatedOpacity(
          opacity: hovered || additionalVisibility ? 1.0 : 0.0,
          duration: opacityDuration,
          child: Tooltip(
            message: message,
            triggerMode: TooltipTriggerMode.manual,
            waitDuration: Duration(seconds: 3),
            verticalOffset: coverWidth / 8,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: icon,
                iconSize: coverWidth * Globals.overlyPlayoutButtonSizeFactor,
                hoverColor: ColorDefs.hoverButtonBackground,
                color: iconColor,
                onPressed: () => onPressed(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
