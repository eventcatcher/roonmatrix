import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

class RichParser extends SpecialTextSpanBuilder {
  // erkennt z. B. [bold red]
  static final _startTagRegex = RegExp(r'\[([^\]]+)\]');

  @override
  SpecialText? createSpecialText(
    String flag, {
    required int index,
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    // Wir nutzen diese Methode nicht — sie MUSS aber existieren.
    return null;
  }

  @override
  TextSpan build(
    String data, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    final children = <InlineSpan>[];
    int index = 0;
    final baseStyle = textStyle ?? const TextStyle();

    while (index < data.length) {
      final nextOpen = data.indexOf('[', index);
      if (nextOpen == -1) {
        children.add(TextSpan(text: data.substring(index), style: baseStyle));
        break;
      }

      if (nextOpen > index) {
        children.add(
            TextSpan(text: data.substring(index, nextOpen), style: baseStyle));
      }

      final match = _startTagRegex.matchAsPrefix(data, nextOpen);
      if (match == null) {
        children.add(TextSpan(text: '[', style: baseStyle));
        index = nextOpen + 1;
        continue;
      }

      final tagContent = match.group(1)!.trim(); // z.B. "red", "bold red"
      final startTagEnd = match.end;
      final endTag = '[/$tagContent]';
      final endIndex = data.indexOf(endTag, startTagEnd);

      if (endIndex == -1) {
        children.add(TextSpan(text: '[', style: baseStyle));
        index = nextOpen + 1;
        continue;
      }

      final content = data.substring(startTagEnd, endIndex);

      final parts = tagContent
          .split(RegExp(r'\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final appliedStyle = _styleFromParts(baseStyle, parts);

      children.add(TextSpan(text: content, style: appliedStyle));

      index = endIndex + endTag.length;
    }

    return TextSpan(children: children, style: baseStyle);
  }

  TextStyle _styleFromParts(TextStyle base, List<String> parts) {
    TextStyle result = base;

    for (final p in parts) {
      switch (p.toLowerCase()) {
        case 'bold':
        case 'b':
          result = result.merge(const TextStyle(fontWeight: FontWeight.bold));
          break;
        case 'italic':
        case 'i':
          result = result.merge(const TextStyle(fontStyle: FontStyle.italic));
          break;
        case 'underline':
        case 'u':
          result = result
              .merge(const TextStyle(decoration: TextDecoration.underline));
          break;
        case 'strike':
        case 's':
          result = result
              .merge(const TextStyle(decoration: TextDecoration.lineThrough));
          break;
        case 'dim':
          result = result.merge(const TextStyle(color: Colors.grey));
          break;

        /// Farben
        case 'red':
        case 'orange':
        case 'green':
        case 'green4':
        case 'deep_sky_blue4':
        case 'blue':
        case 'bright_magenta':
        case 'magenta':
          result = result.merge(TextStyle(color: _colorFromName(p)));
          break;

        default:
          if (p.startsWith('bg-')) {
            final colName = p.substring(3);
            final bg = _colorFromName(colName);
            if (bg != null) {
              result = result.merge(TextStyle(backgroundColor: bg));
            }
          }
      }
    }

    return result;
  }

  Color? _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Color(0xFFffaf00);
      case 'green':
        return Color(0xFF146710);
      case 'green4':
        return Color(0xFF008700);
      case 'deep_sky_blue4':
        return Color(0xFF005faf);
      case 'blue':
        return Color(0xFF080767);
      case 'bright_magenta':
        return Color(0xFFFF01FF);
      case 'magenta':
        return Color(0xFF680d68);
    }
    return null;
  }
}
