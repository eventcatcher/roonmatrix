import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cup;
import 'package:roonmatrix/globals.dart';

class AlertElement extends StatelessWidget {
  const AlertElement({
    super.key,
    required this.title,
    this.icon,
    this.content,
    required this.button1Label,
    required this.onPressed1,
    required this.button2Label,
    this.onPressed2,
  });

  final String title;
  final Widget? icon;
  final Widget? content;
  final String button1Label;
  final VoidCallback onPressed1;
  final String button2Label;
  final VoidCallback? onPressed2;

  @override
  Widget build(BuildContext context) {
    return Globals.inMacosStyle() || Globals.inIosStyle()
        ? cup.CupertinoAlertDialog(
            title: icon != null
                ? Column(children: [icon!, Text(title)])
                : Text(title),
            content: content,
            actions: [
              if (button1Label.isNotEmpty)
                cup.CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    onPressed1();
                  },
                  child: Text(button1Label),
                ),
              if (button2Label.isNotEmpty)
                cup.CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: onPressed2 != null ? () => onPressed2!() : null,
                  child: Text(button2Label),
                ),
            ],
          )
        : AlertDialog(
            title: icon != null
                ? Column(children: [icon!, Text(title)])
                : Text(title),
            content: content,
            actions: [
              if (button1Label.isNotEmpty)
                TextButton(
                  child: Text(button1Label),
                  onPressed: () {
                    onPressed1();
                  },
                ),
              if (button2Label.isNotEmpty)
                TextButton(
                  onPressed: onPressed2 != null ? () => onPressed2!() : null,
                  child: Text(button2Label),
                ),
            ],
          );
  }
}
