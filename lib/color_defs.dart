import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/globals.dart';

class ColorDefs {
  static Color textColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? CupertinoColors.white
          : CupertinoColors.black;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.white
          : MacosColors.black;
    }
    return Theme.of(context).colorScheme.inverseSurface;
  }

  static Color iconColor({
    required BuildContext context,
  }) =>
      textColor(context: context);

  static Color hintColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return CupertinoColors.systemGrey;
    }
    if (Globals.inMacosStyle()) {
      return MacosColors.systemGrayColor;
    }
    return Theme.of(context).hintColor;
  }

  static Color windowBackgroundColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.underPageBackgroundColor
          : CupertinoColors.white;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.underPageBackgroundColor
          : MacosColors.white;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color borderColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 60, 60, 60)
          : MacosColors.tickBackgroundColor;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.systemGrayColor
          : MacosColors.tickBackgroundColor;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color elementBackgroundColorLighter({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? Theme.of(context).primaryColorLight
          : CupertinoColors.white;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? Theme.of(context).primaryColorLight
          : Colors.white;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color elementBackgroundColor({
    required BuildContext context,
  }) =>
      windowBackgroundColor(context: context);

  static Color selectboxBackgroundColor({
    required BuildContext context,
  }) =>
      Globals.brightness() == Brightness.dark
          ? Colors.grey.shade800
          : MacosColors.white;

  static Color areaBackgroundColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade100;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade100;
    }
    return Globals.brightness() == Brightness.dark
        ? Color.fromARGB(255, 57, 55, 60)
        : Colors.grey.shade100;
  }

  static Color toolbarBackgroundColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.controlColor
          : const Color.fromARGB(255, 195, 219, 239);
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.controlColor
          : const Color.fromARGB(255, 195, 219, 239);
    }
    return Globals.brightness() == Brightness.dark
        ? Colors.black26
        : const Color.fromARGB(255, 195, 219, 239);
  }

  static Color coverRowBackgroundColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade200;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade200;
    }
    return Globals.brightness() == Brightness.dark
        ? const Color.fromARGB(255, 57, 55, 60)
        : Colors.grey.shade200;
  }

  static Color resetIconColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 171, 39, 32)
          : CupertinoColors.systemRed;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 171, 39, 32)
          : MacosColors.appleRed;
    }
    return Globals.brightness() == Brightness.dark
        ? const Color.fromARGB(255, 171, 39, 32)
        : Colors.red.shade700;
  }

  static Color tileBackgroundColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.blue.shade100;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.blue.shade100; // MacosColors.systemTealColor;
    }
    return Globals.brightness() == Brightness.dark
        ? const Color.fromARGB(255, 57, 55, 60)
        : Colors.blue.shade100;
  }

  static Color buttonBlueColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : CupertinoColors.systemBlue;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : MacosColors.systemBlueColor; // MacosColors.systemTealColor;
    }
    return Globals.brightness() == Brightness.dark
        ? Colors.grey.shade700
        : Colors.blue.shade700;
  }

  static Color blueIconColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? CupertinoColors.white
          : CupertinoColors.systemBlue;
    }
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.white
          : MacosColors.systemBlueColor; // MacosColors.systemTealColor;
    }
    return Globals.brightness() == Brightness.dark
        ? Colors.white
        : Colors.blue.shade700;
  }

  static Color buttonRowBackgroundColor({
    required BuildContext context,
  }) =>
      Globals.brightness() == Brightness.dark
          ? Colors.grey.shade600
          : Colors.blue.shade300;

  static Color textFieldBackgroundColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      //return windowBackgroundColor(context: context);
      return Globals.brightness() == Brightness.dark
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemBackground;
    }
    //alternatingContentBackgroundColor, underPageBackgroundColor
    if (Globals.inMacosStyle()) {
      return Globals.brightness() == Brightness.dark
          ? MacosColors.alternatingContentBackgroundColor
          : Color(0xffefefef);
    }
    return windowBackgroundColor(context: context);
  }

  static Color toolbarResizeButtonColor({
    required BuildContext context,
  }) {
    if (Globals.inIosStyle()) {
      return CupertinoColors.systemGrey;
    }
    if (Globals.inMacosStyle()) {
      return MacosColors.systemGrayColor;
    }
    return Globals.brightness() == Brightness.dark
        ? Colors.grey.shade300
        : Colors.white;
  }

  static Color bugerMenuHeadlineColor({
    required BuildContext context,
  }) {
    return Globals.inIosStyle() ? CupertinoColors.systemGrey : Colors.blue;
  }
}
