import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';

class VirtualDeviceInfo extends StatefulWidget {
  const VirtualDeviceInfo({
    super.key,
    required this.translations,
    required this.show,
    required this.withAnimation,
  });

  final Map<String, dynamic> translations;
  final bool show;
  final bool withAnimation;

  @override
  State<VirtualDeviceInfo> createState() => _VirtualDeviceInfoState();
}

class _VirtualDeviceInfoState extends State<VirtualDeviceInfo>
    with TickerProviderStateMixin {
  final double tileListHeight = 84;

  late Animation<double> controllerAnimation;
  late AnimationController controller;

  Map<String, dynamic> get translations => widget.translations;
  bool get show => widget.show;
  bool get withAnimation => widget.withAnimation;

  @override
  initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    final CurvedAnimation curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    controllerAnimation = Tween(begin: 0.0, end: 1.0).animate(curve);
    controller.forward();
  }

  Widget defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, widget) {
        return Opacity(
          opacity: controllerAnimation.value,
          child: FadeTransition(opacity: controllerAnimation, child: widget),
        );
      },
      child: child,
    );
  }

  Widget tile() => Container(
    decoration: BoxDecoration(
      color: ColorDefs.tileBackgroundColor(context: context),
      border: Border(
        top: BorderSide(width: 1, color: Colors.white),
        bottom: BorderSide(width: 1, color: Colors.white),
      ),
    ),
    height: tileListHeight,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            translations['startingVirtualDeviceInfo'] ??
                'Starting virtual device',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: ColorDefs.blueIconColor(context: context),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return withAnimation
        ? AnimatedSwitcher(
            duration: Duration(seconds: 1),
            transitionBuilder: defaultTransitionBuilder,
            child: show ? tile() : SizedBox(),
          )
        : show
        ? tile()
        : SizedBox();
  }
}
