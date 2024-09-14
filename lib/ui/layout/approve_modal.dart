import 'package:flutter/material.dart';

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

  ApproveModal(
      {required this.context,
      required this.question,
      this.landscape = false,
      this.icon,
      this.title = 'Löschen',
      this.okText = 'OK',
      this.cancelText = 'Abbrechen',
      VoidCallback? onCanceled,
      VoidCallback? onApproved})
      : onCanceled = onCanceled ?? (() {}),
        onApproved = onApproved ?? (() {});

  Future<dynamic> show() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return RotatedBox(
              quarterTurns:
                  (landscape && orientation == Orientation.portrait) ? 1 : 0,
              child: AlertDialog(
                title: Column(
                  children: [
                    if (icon != null) icon!,
                    Text(title),
                  ],
                ),
                content:
                    Text(question, softWrap: true, textAlign: TextAlign.center),
                actions: [
                  if (cancelText != '')
                    TextButton(
                      child: Text(cancelText),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCanceled!();
                      },
                    ),
                  TextButton(
                    child: Text(okText),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onApproved!();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
