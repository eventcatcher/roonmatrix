import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';

class CoverOverlayButton extends StatefulWidget {
  final Alignment alignment;
  final double coverWidth;
  final bool isPlaying;
  final bool additionalVisibility;
  final double? sizeFactor;
  final SvgPicture? svg;
  final Icon icon;
  final String message;
  final VoidCallback onPressed;

  const CoverOverlayButton({
    super.key,
    required this.alignment,
    required this.coverWidth,
    required this.isPlaying,
    this.additionalVisibility = false,
    this.sizeFactor = 1.0,
    required this.icon,
    this.svg,
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
  bool get isPlaying => widget.isPlaying;
  double get sizeFactor => widget.sizeFactor!;
  SvgPicture? get svg => widget.svg;
  Icon get icon => widget.icon;
  String get message => widget.message;
  VoidCallback get onPressed => widget.onPressed;

  final Duration opacityDuration = const Duration(milliseconds: 200);

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
            waitDuration: Globals.controlButtonTooltipWaitDuration,
            verticalOffset:
                (coverWidth *
                    Globals.overlyPlayoutButtonSizeFactor *
                    sizeFactor) /
                2,
            child: Container(
              child: svg != null
                  ? SizedBox(
                      width:
                          (coverWidth *
                          Globals.overlyPlayoutButtonSizeFactor *
                          sizeFactor),
                      height:
                          (coverWidth *
                          Globals.overlyPlayoutButtonSizeFactor *
                          sizeFactor),
                      child: InkWell(
                        mouseCursor: SystemMouseCursors.click,
                        child: Padding(
                          padding: EdgeInsets.all(
                            ((coverWidth *
                                        Globals.overlyPlayoutButtonSizeFactor) *
                                    sizeFactor) /
                                6,
                          ),
                          child: svg,
                        ),
                        onTap: () => onPressed(),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Globals.brightness() == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.6),
                        boxShadow: [
                          // dunkler Schatten
                          BoxShadow(
                            color: Globals.brightness() == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.45)
                                : Colors.black.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),

                          // heller Glow
                          BoxShadow(
                            color: Globals.brightness() == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        mouseCursor: SystemMouseCursors.click,
                        icon: icon,
                        iconSize:
                            (coverWidth *
                            Globals.overlyPlayoutButtonSizeFactor *
                            sizeFactor),
                        hoverColor: Globals.brightness() == Brightness.dark
                            ? ColorDefs.hoverOverlayButtonBackgroundDark
                            : ColorDefs.hoverOverlayButtonBackgroundLight,
                        highlightColor: Globals.brightness() == Brightness.dark
                            ? ColorDefs.hoverOverlayButtonBackgroundDark
                                  .withValues(alpha: 0.5)
                            : ColorDefs.hoverOverlayButtonBackgroundLight
                                  .withValues(alpha: 0.5),
                        color: Globals.brightness() == Brightness.dark
                            ? ColorDefs.controlIconColorLight
                            : ColorDefs.controlIconColorDark,
                        onPressed: () => onPressed(),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
