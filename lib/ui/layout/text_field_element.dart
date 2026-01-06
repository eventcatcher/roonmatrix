import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class TextFieldElement extends StatelessWidget {
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
    this.borderColor = Colors.transparent,
    this.fillColor,
    this.suffixIcon,
    this.autofocus = false,
    required this.controller,
    this.style,
    this.onChanged,
  });

  final String? placeholder;
  final Widget? prefixIcon;
  final bool readOnly;
  final int? maxLength;
  final InputCounterWidgetBuilder? buildCounter;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController controller;
  final Color borderColor;
  final Color? fillColor;
  final dynamic suffixIcon;
  final bool autofocus;
  final TextStyle? style;
  final Function(String value)? onChanged;

  @override
  Widget build(BuildContext context) {
    if (SharedWidgets.inIosStyle()) {
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
        style: SharedWidgets.inMacosStyle() || SharedWidgets.inIosStyle()
            ? null
            : style,
        decoration: SharedWidgets.inIosStyle()
            ? null
            : BoxDecoration(
                color: SharedWidgets.textFieldBackgroundColor(context: context),
              ),
        controller: controller,
        onChanged: onChanged,
      );
    }

    return SharedWidgets.inMacosStyle()
        ? MacosTextField(
            placeholder: placeholder,
            placeholderStyle:
                TextStyle(color: SharedWidgets.hintColor(context: context)),
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
              color: SharedWidgets.textFieldBackgroundColor(context: context),
            ),
            focusedDecoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5),
              ),
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
