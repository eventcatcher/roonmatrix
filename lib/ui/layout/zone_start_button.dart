import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class ZoneStartButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ZoneStartButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: SharedWidgets.isDesktopDevice()
            ? IconTextButtonElement(
                onMacAsText: true,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Icon(
                    Icons.open_with,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
                label: label,
                onPressed: () => onPressed(),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  shadowColor: Colors.transparent,
                  backgroundColor:
                      SharedWidgets.buttonBlueColor(context: context),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: Platform.isIOS ? 5.0 : 7.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => onPressed(),
                child: Text(label),
              ),
      );
}
