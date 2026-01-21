import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class ApproveModal {
  final BuildContext context;
  final Widget? icon;
  final String title;
  final String question;
  final String okText;
  final String cancelText;
  final bool landscape;
  final VoidCallback? onCanceled;
  final VoidCallback? onApproved;

  ApproveModal({
    required this.context,
    required this.question,
    this.landscape = false,
    this.icon,
    this.title = 'Löschen',
    this.okText = 'OK',
    this.cancelText = 'Abbrechen',
    VoidCallback? onCanceled,
    VoidCallback? onApproved,
  })  : onCanceled = onCanceled ?? (() {}),
        onApproved = onApproved ?? (() {});

  Future<dynamic> show() {
    return SharedWidgets.showPlatformSpecificDialog(
      context: context,
      barrierDismissible: false,
      child: (BuildContext context) => OrientationBuilder(
        builder: (context, orientation) {
          return RotatedBox(
            quarterTurns:
                (landscape && orientation == Orientation.portrait) ? 1 : 0,
            child: AlertElement(
              icon: icon,
              title: title,
              content: Text(
                question,
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharedWidgets.textColor(context: context),
                ),
              ),
              button1Label: cancelText,
              onPressed1: () {
                Navigator.of(context).pop();
                onCanceled!();
              },
              button2Label: okText,
              onPressed2: () {
                Navigator.of(context).pop();
                onApproved!();
              },
            ),
          );
        },
      ),
    );
  }
}
