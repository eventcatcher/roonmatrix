import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';

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
        child: Globals.isDesktopDevice() &&
                MediaQuery.of(context).size.width >
                    Globals.mobilePageButtonsMaxWidth
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
                    Icons.start,
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
                  backgroundColor: ColorDefs.buttonBlueColor(context: context),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: Globals.isDesktopDevice()
                          ? Globals.inMacosStyle() || Globals.inIosStyle()
                              ? 13
                              : 15
                          : Platform.isIOS
                              ? 5.0
                              : 7.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => onPressed(),
                child: Text(label),
              ),
      );
}
