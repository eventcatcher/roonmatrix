import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class Headline extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const Headline({
    super.key,
    required this.text,
    this.fontSize = 24.0,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: 5.0),
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: SharedWidgets.textColor(context: context),
        ),
      ),
    );
  }
}
