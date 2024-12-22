import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:flutter/material.dart';

class ApproveModal {
  final BuildContext context;
  final bool showMacStyle;
  final Widget? icon;
  final String title;
  final String question;
  final String okText;
  final String cancelText;
  final bool landscape;
  final VoidCallback? onCanceled;
  final VoidCallback? onApproved;

  ApproveModal({
    required this.showMacStyle,
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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return RotatedBox(
              quarterTurns:
                  (landscape && orientation == Orientation.portrait) ? 1 : 0,
              child: AlertElement(
                showMacStyle: showMacStyle,
                title: title,
                icon: icon,
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
                content:
                    Text(question, softWrap: true, textAlign: TextAlign.center),
              ),
            );
          },
        );
      },
    );
  }
}
