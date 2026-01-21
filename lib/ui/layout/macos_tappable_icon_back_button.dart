import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class MacosTappableIconBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const MacosTappableIconBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MacosBackButton(
      fillColor: Colors.transparent,
      hoverColor: Colors.transparent,
      mouseCursor: SystemMouseCursors.click,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        }
        Navigator.pop(context);
      },
    );
  }
}
