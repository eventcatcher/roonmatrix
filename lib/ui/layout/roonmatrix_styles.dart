import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

abstract class RoonmatrixStyles {
  static dynamic boxDecoration = ({Color? fillColor}) => BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(SharedWidgets.inIosStyle() ? 8 : 5),
        border: Border.all(
            color: Colors.grey.shade300, width: 0, style: BorderStyle.solid),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(3, 3), // changes position of shadow
          ),
        ],
      );

  static dynamic inputDecoration = ({
    String? placeholder,
    String? label,
    dynamic prefixIcon,
    dynamic suffixIcon,
    Color? fillColor,
    Color? borderColor,
    bool? noCounter,
    bool? filled,
  }) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      border: InputBorder.none,
      fillColor: fillColor ?? Colors.white,
      filled: filled ?? true,
      hintText: placeholder,
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      alignLabelWithHint: true,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      counterText: noCounter == true ? '' : null,
      prefixIconConstraints: const BoxConstraints(minHeight: 28, minWidth: 28),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: borderColor ?? Colors.grey.shade300,
              width: borderColor != null ? 2 : 0)),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: borderColor ?? Colors.grey.shade300,
              width: borderColor != null ? 2 : 0)),
      disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0)),
    );
  };
}
