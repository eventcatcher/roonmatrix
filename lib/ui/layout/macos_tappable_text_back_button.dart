import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class MacosTappableTextBackButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const MacosTappableTextBackButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: ThemeData(
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
        ),
        child: InkWell(
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            }
            Navigator.pop(context);
          },
          child: Text(
            text,
            style: TextStyle(
              color: SharedWidgets.textColor(context: context),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
