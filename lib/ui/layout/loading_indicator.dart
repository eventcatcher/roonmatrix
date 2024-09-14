import 'package:flutter/material.dart';

class LoadingIndicatorBig extends StatelessWidget {
  final String? message;

  const LoadingIndicatorBig({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Stack(
          children: <Widget>[
            SizedBox(
              height: 200.0,
              width: 200.0,
              child: Center(
                  child: Transform.scale(
                scale: 5,
                child: const Center(
                    child: CircularProgressIndicator(
                  strokeWidth: 1,
                )),
              )),
            ),
            SizedBox(
                height: 200.0,
                width: 200.0,
                child: Center(child: Text(message!)))
          ],
        ),
      );
}
