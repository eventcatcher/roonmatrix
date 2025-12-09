import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class RichParser extends SpecialTextSpanBuilder {
  // erlaubte Tag-Namen:
  // Wörter: a-z, A-Z, Zahlen, -, _
  // mehrere Wörter erlaubt: "bold red"
  static final _startTagRegex = RegExp(r'^[a-zA-Z0-9_-]+(\s+[a-zA-Z0-9_-]+)*$');

  static final _endTagRegex = RegExp(r'^/[a-zA-Z0-9_-]+(\s+[a-zA-Z0-9_-]+)*$');

  @override
  SpecialText? createSpecialText(String flag,
      {required int index,
      TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap}) {
    return null; // unused
  }

  @override
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    final baseStyle = textStyle ?? const TextStyle();
    final stack = <_Frame>[];
    stack.add(_Frame(tagName: null, style: baseStyle));

    int i = 0;

    while (i < data.length) {
      if (data[i] == '[') {
        final close = data.indexOf(']', i + 1);

        if (close == -1) {
          // Kein schließendes ']', treat as normal text.
          stack.last.children.add(TextSpan(text: '[', style: stack.last.style));
          i++;
          continue;
        }

        final inside = data.substring(i + 1, close).trim();

        // **END TAG**
        if (_endTagRegex.hasMatch(inside)) {
          final tagName = inside.substring(1).trim();

          if (stack.length > 1 && stack.last.tagName == tagName) {
            final popped = stack.removeLast();
            final built =
                TextSpan(children: popped.children, style: popped.style);
            stack.last.children.add(built);
          } else {
            // mismatched end tag → as literal text
            stack.last.children.add(TextSpan(
                text: data.substring(i, close + 1), style: stack.last.style));
          }

          i = close + 1;
          continue;
        }

        // **START TAG**
        if (_startTagRegex.hasMatch(inside)) {
          final parts = inside
              .split(RegExp(r'\s+'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          if (parts.isNotEmpty) {
            final newStyle = _styleFromParts(stack.last.style, parts);
            stack.add(_Frame(tagName: inside, style: newStyle));
            i = close + 1;
            continue;
          }
        }

        // nicht als Tag erkennbar → raw
        stack.last.children.add(TextSpan(
            text: data.substring(i, close + 1), style: stack.last.style));
        i = close + 1;
        continue;
      }

      // Normales Zeichenblock
      final next = data.indexOf('[', i);
      final end = next == -1 ? data.length : next;
      final segment = data.substring(i, end);
      stack.last.children.add(TextSpan(text: segment, style: stack.last.style));
      i = end;
    }

    // Ungeschlossene Tags sauber beenden
    while (stack.length > 1) {
      final popped = stack.removeLast();
      final literalStart = "[${popped.tagName}]";

      stack.last.children.add(TextSpan(
        children: [
          TextSpan(text: literalStart, style: stack.last.style),
          ...popped.children
        ],
        style: popped.style,
      ));
    }

    return TextSpan(children: stack.first.children, style: baseStyle);
  }

  // --------------------------------------------------
  // STYLE SYSTEM
  // --------------------------------------------------

  TextStyle _styleFromParts(TextStyle base, List<String> parts) {
    var result = base;

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

        // Farben
        case 'red':
        case 'orange':
        case 'green':
        case 'green4':
        case 'deep_sky_blue4':
        case 'blue':
        case 'bright_magenta':
        case 'magenta':
          final c = _colorFromName(p);
          if (c != null) result = result.merge(TextStyle(color: c));
          break;

        default:
          if (p.startsWith('bg-')) {
            final c = _colorFromName(p.substring(3));
            if (c != null) {
              result = result.merge(TextStyle(backgroundColor: c));
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
        return SharedWidgets.brightness() == Brightness.dark
            ? const Color.fromARGB(186, 255, 174, 0)
            : const Color(0xFFffaf00);
      case 'green':
        return SharedWidgets.brightness() == Brightness.dark
            ? const Color.fromARGB(255, 78, 151, 74)
            : const Color(0xFF146710);
      case 'green4':
        return SharedWidgets.brightness() == Brightness.dark
            ? const Color.fromARGB(255, 136, 200, 133)
            : const Color(0xFF008700);
      case 'deep_sky_blue4':
        return SharedWidgets.brightness() == Brightness.dark
            ? Color.fromARGB(255, 51, 133, 200)
            : const Color(0xFF005faf);
      case 'blue':
        return SharedWidgets.brightness() == Brightness.dark
            ? const Color.fromARGB(255, 63, 60, 249)
            : const Color(0xFF080767);
      case 'bright_magenta':
        return const Color(0xFFFF01FF);
      case 'magenta':
        return SharedWidgets.brightness() == Brightness.dark
            ? const Color.fromARGB(255, 221, 27, 221)
            : const Color(0xFF680d68);
    }
    return null;
  }
}

class _Frame {
  _Frame({required this.tagName, required this.style}) {
    children = <InlineSpan>[];
  }

  final String? tagName; // null for root
  final TextStyle style;
  late List<InlineSpan> children;
}
