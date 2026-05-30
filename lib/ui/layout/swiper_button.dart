import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';

class SwiperButton extends StatefulWidget {
  final SwiperController swiperController;
  final bool outer;
  final bool isNext;
  final double center;
  final double size;

  const SwiperButton({
    super.key,
    required this.swiperController,
    required this.outer,
    required this.isNext,
    required this.center,
    this.size = 40.0,
  });

  @override
  State<SwiperButton> createState() => _SwiperButtonState();
}

class _SwiperButtonState extends State<SwiperButton> {
  bool swiperButtonHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.outer ? -8 : 12,
      left: widget.isNext ? null : widget.center - 50,
      right: widget.isNext ? widget.center - 50 : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => Globals.isDesktopDevice()
            ? setState(() => swiperButtonHovered = true)
            : null,
        onExit: (_) => Globals.isDesktopDevice()
            ? setState(() => swiperButtonHovered = false)
            : null,
        child: GestureDetector(
          onTap: () {
            widget.isNext
                ? widget.swiperController.next()
                : widget.swiperController.previous();
          },
          child: Icon(
            widget.isNext ? Icons.arrow_right : Icons.arrow_left,
            size: widget.size,
            color: swiperButtonHovered == true
                ? Colors.blue
                : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
