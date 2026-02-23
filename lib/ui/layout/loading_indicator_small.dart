import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';

class LoadingIndicatorSmall extends StatelessWidget {
  final String? message;

  const LoadingIndicatorSmall({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (message != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(message!)),
            CircularProgressIndicator(
              color: ColorDefs.blueIconColor(context: context),
            ),
          ],
        ),
      );
}
