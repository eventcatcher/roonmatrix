import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';

class HorizontalScrollButton extends StatefulWidget {
  final ScrollController scrollController;
  final double width;
  final double height;
  final bool isRight;

  const HorizontalScrollButton({
    super.key,
    required this.scrollController,
    required this.width,
    required this.height,
    required this.isRight,
  });

  @override
  State<HorizontalScrollButton> createState() => _HorizontalScrollButtonState();
}

class _HorizontalScrollButtonState extends State<HorizontalScrollButton> {
  bool buttonHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.isRight ? null : 0,
      right: widget.isRight ? 0 : null,
      child: SizedBox(
        width: 20.0,
        height: widget.height,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => Globals.isDesktopDevice()
              ? setState(() => buttonHovered = true)
              : null,
          onExit: (_) => Globals.isDesktopDevice()
              ? setState(() => buttonHovered = false)
              : null,
          child: GestureDetector(
            onTap: () {
              widget.isRight
                  ? widget.scrollController.animateTo(
                      widget.scrollController.offset + widget.width / 2,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    )
                  : widget.scrollController.animateTo(
                      widget.scrollController.offset - widget.width / 2,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
            },
            child: buttonHovered == true
                ? Container(
                    decoration: ShapeDecoration(
                      color: Globals.brightness() == Brightness.dark
                          ? Color.fromARGB(130, 220, 220, 220)
                          : Color.fromARGB(200, 70, 70, 70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(0.0),
                          bottomRight: Radius.circular(0.0),
                        ),
                      ),
                    ),
                    child: Container(
                      transform: Matrix4.translationValues(-16, 0, 0),
                      child: Icon(
                        widget.isRight ? Icons.arrow_right : Icons.arrow_left,
                        size: 50.0,
                        color: Globals.brightness() == Brightness.dark
                            ? ColorDefs.controlIconColorDark
                            : ColorDefs.controlIconColorLight,
                      ),
                    ),
                  )
                : SizedBox(),
          ),
        ),
      ),
    );
  }
}
