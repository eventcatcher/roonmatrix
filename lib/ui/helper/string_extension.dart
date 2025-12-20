import 'dart:math';

import 'package:intl/intl.dart';

extension StringCasingExtension on String {
  String get toFirstUpper =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  String get toCapitalized =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String get toTitleCase => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized)
      .join(' ');
}

extension FileFormatter on num {
  String readableFileSize({bool base1024 = true}) {
    final base = base1024 ? 1024 : 1000;
    if (this <= 0) return "0";
    final units = ["B", "kB", "MB", "GB", "TB"];
    int digitGroups = (log(this) / log(base)).round();
    return '${NumberFormat("#,##0.#").format(this / pow(base, digitGroups))} ${units[digitGroups]}';
  }
}

extension NumericBracketFilter on String {
  String removeNumericBrackets() {
    return replaceAllMapped(
      RegExp(r'\[(\d+)\]'),
      (_) => '',
    ).replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}

extension EmptyBracketFilter on String {
  String removeEmptyBrackets() {
    return replaceAll(RegExp(r'\[\s*\]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
