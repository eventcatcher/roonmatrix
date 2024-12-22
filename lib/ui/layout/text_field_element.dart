import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class TextFieldElement extends StatelessWidget {
  const TextFieldElement({
    super.key,
    required this.showMacStyle,
    this.placeholder,
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

  final bool showMacStyle;
  final String? placeholder;
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
    return showMacStyle == true && Platform.isMacOS
        ? MacosTextField(
            placeholder: placeholder,
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            clearButtonMode: OverlayVisibilityMode.always,
            readOnly: readOnly,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            suffix: suffixIcon,
            style: style,
            controller: controller,
            decoration: BoxDecoration(
              color: SharedWidgets.textFieldBackgroundColor(
                  showMacStyle: showMacStyle, context: context),
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
