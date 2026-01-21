import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

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
        onEnter: (_) => SharedWidgets.isDesktopDevice()
            ? setState(() => hovered = true)
            : null,
        onExit: (_) => SharedWidgets.isDesktopDevice()
            ? setState(() => hovered = false)
            : null,
        child: AnimatedOpacity(
          opacity: hovered || additionalVisibility ? 1.0 : 0.0,
          duration: opacityDuration,
          child: Tooltip(
            message: message,
            triggerMode: TooltipTriggerMode.manual,
            waitDuration: Duration(seconds: 3),
            verticalOffset: coverWidth / 8,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: SharedWidgets.hoverButtonBackground,
              ),
              icon: icon,
              iconSize: coverWidth / 4,
              color: iconColor,
              onPressed: () => onPressed(),
            ),
          ),
        ),
      ),
    );
  }
}
