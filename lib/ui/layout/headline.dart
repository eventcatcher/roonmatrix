import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class Headline extends StatelessWidget {
  final String text;

  const Headline({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: 5.0),
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: SharedWidgets.textColor(context: context),
        ),
      ),
    );
  }
}
