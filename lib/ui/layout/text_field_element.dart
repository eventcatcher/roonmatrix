import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';

class TextFieldElement extends StatelessWidget {
  final String? placeholder;
  final Widget? prefixIcon;
  final bool readOnly;
  final int? maxLength;
  final InputCounterWidgetBuilder? buildCounter;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController controller;
  final dynamic suffixIcon;
  final bool autofocus;
  final TextStyle? style;
  final Function(String value)? onChanged;

  const TextFieldElement({
    super.key,
    this.placeholder,
    this.prefixIcon,
    this.readOnly = false,
    this.maxLength,
    this.buildCounter,
    this.keyboardType,
    this.decoration,
    this.inputFormatters,
    required this.controller,
    this.suffixIcon,
    this.autofocus = false,
    this.style,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Globals.inIosStyle()) {
      return cup.CupertinoTextField(
        placeholder: placeholder,
        prefix: prefixIcon != null
            ? cup.Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: prefixIcon,
              )
            : null,
        suffix: suffixIcon,
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        clearButtonMode: readOnly
            ? cup.OverlayVisibilityMode.never
            : cup.OverlayVisibilityMode.always,
        readOnly: readOnly,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: Globals.inMacosStyle() || Globals.inIosStyle() ? null : style,
        decoration: Globals.inIosStyle()
            ? null
            : BoxDecoration(
                color: ColorDefs.textFieldBackgroundColor(context: context),
              ),
        controller: controller,
        onChanged: onChanged,
      );
    }

    return Globals.inMacosStyle()
        ? MacosTextField(
            placeholder: placeholder,
            placeholderStyle:
                TextStyle(color: ColorDefs.hintColor(context: context)),
            prefix: prefixIcon,
            padding: EdgeInsets.symmetric(
                horizontal: prefixIcon != null ? 0.0 : 8.0, vertical: 4.0),
            clearButtonMode: readOnly
                ? OverlayVisibilityMode.never
                : OverlayVisibilityMode.always,
            readOnly: readOnly,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            suffix: suffixIcon,
            suffixMode: OverlayVisibilityMode.always,
            style: style,
            controller: controller,
            decoration: BoxDecoration(
              color: ColorDefs.textFieldBackgroundColor(context: context),
            ),
            focusedDecoration: BoxDecoration(
              borderRadius: Globals.borderRadius(),
            ),
            onChanged: onChanged,
          )
        : TextField(
            readOnly: readOnly,
            autofocus: autofocus,
            maxLength: maxLength,
            buildCounter: buildCounter,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: decoration,
            style: style,
            controller: controller,
            onChanged: onChanged,
          );
  }
}
