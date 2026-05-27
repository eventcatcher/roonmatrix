import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';

class SwiperButton extends StatefulWidget {
  final SwiperController swiperController;
  final bool isNext;
  final double top;
  final double right;
  final double size;

  const SwiperButton({
    super.key,
    required this.swiperController,
    required this.isNext,
    required this.top,
    this.right = 0,
    this.size = 48.0,
  });

  @override
  State<SwiperButton> createState() => _SwiperButtonState();
}

class _SwiperButtonState extends State<SwiperButton> {
  bool swiperButtonHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.isNext ? null : 0,
      right: widget.isNext ? widget.right : null,
      child: MouseRegion(
        onEnter: (_) => Globals.isDesktopDevice()
            ? setState(() => swiperButtonHovered = true)
            : null,
        onExit: (_) => Globals.isDesktopDevice()
            ? setState(() => swiperButtonHovered = false)
            : null,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          onPressed: () {
            widget.isNext
                ? widget.swiperController.next()
                : widget.swiperController.previous();
          },
          icon: Icon(
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
