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
    final int base = base1024 ? 1024 : 1000;
    if (this <= 0) return "0";
    final List<String> units = ["B", "kB", "MB", "GB", "TB"];
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

extension ReplaceDoubleQuotesWithSingleQuotes on String {
  String replaceDoubleQuotesWithSingleQuotes() {
    return replaceAll('"', "'");
  }
}

extension ReplaceQuotesWithSpecialTags on String {
  String replaceQuotesWithSpecialTags() {
    return replaceAll('\'', '[q]')
        .replaceAll('\\"', '[dq]')
        .replaceAll('"', "'");
  }
}

extension ReplaceSpecialTagsWithQuotes on String {
  String replaceSpecialTagsWithQuotes() {
    return replaceAll("'", '"')
        .replaceAll('[q]', "'")
        .replaceAll('[dq]', "\\\"");
  }
}

extension EscapeAllSpecialChars on String {
  String escapeAllSpecialChars() {
    return replaceAllMapped(
      RegExp(r'[-\/\\^$*+?.()|[\]{}]'),
      (m) => '\\${m[0]}',
    );
  }
}

extension OnlyMatchedLinesFilter on String {
  String onlyMatchedLinesFilter({
    required String logstr,
    required bool filterLog,
    required String match,
  }) {
    if (!filterLog || logstr.isEmpty) {
      return logstr;
    }

    List<String> matchedLines = [];
    List<String> lines = logstr.split('\n');
    for (String line in lines) {
      if (line.contains(match)) {
        matchedLines.add(line);
      }
    }

    return matchedLines.join('\n');
  }
}
