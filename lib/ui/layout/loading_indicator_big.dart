import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';

class LoadingIndicatorBig extends StatelessWidget {
  final String? message;
  final double? size;
  final double? scale;
  final double? strokeWidth;

  const LoadingIndicatorBig({
    super.key,
    this.message,
    this.size = 200.0,
    this.scale = 5.0,
    this.strokeWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Stack(
          children: <Widget>[
            SizedBox(
              height: size,
              width: size,
              child: Center(
                  child: Transform.scale(
                scale: scale,
                child: Center(
                    child: CircularProgressIndicator(
                  strokeWidth: strokeWidth,
                  color: ColorDefs.blueIconColor(context: context),
                )),
              )),
            ),
            SizedBox(
              height: size,
              width: size,
              child: Center(
                child: Text(
                  message!,
                  style: TextStyle(
                    color: ColorDefs.textColor(context: context),
                  ),
                ),
              ),
            )
          ],
        ),
      );
}
