import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class UpdatableTicker extends StatefulWidget {
  final String newText;
  final TextStyle style;

  final double pixelsPerSecond;

  const UpdatableTicker({
    required this.newText,
    required this.style,
    this.pixelsPerSecond = 30.0,
    super.key,
  });

  @override
  State<UpdatableTicker> createState() => _UpdatableTickerState();
}

class _UpdatableTickerState extends State<UpdatableTicker>
    with SingleTickerProviderStateMixin {
  final int loopsToFill = 3;

  List<String> textBuffer = [];
  String oldText = '';
  String newText = '';
  String renderedText = '';

  double containerWidth = 0.0;
  double newTextWidth = 0.0;
  double posToUpdate = 0.0;
  double offset = 0.0;

  int minRepeatCountNewText = 1;

  late final Ticker ticker;

  @override
  void initState() {
    super.initState();
    newText = widget.newText;
    textBuffer.add(widget.newText);
    ticker = Ticker(onTick)..start();
  }

  @override
  void didUpdateWidget(UpdatableTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newText != newText) {
      if (oldText.isEmpty) {
        oldText = newText;
      }

      newText = widget.newText;

      if (kDebugMode) {
        debugPrint(
            'xxxx didUpdateWidget, oldText: $oldText, newText: $newText');
      }

      if (containerWidth > 0) {
        updateRenderedText();
      }
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  double measureTextWidth(String text) {
    if (text.isEmpty) return 0;

    final TextScaler textScaler = MediaQuery.of(context).textScaler;

    final tp = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    return tp.width;
  }

  void updateRenderedText() {
    double oldTextWidth = measureTextWidth(oldText);
    newTextWidth = measureTextWidth(newText);

    int minRepeatCountOldText = oldTextWidth > 0
        ? ((offset.abs() + containerWidth) / oldTextWidth).ceil()
        : 0;
    minRepeatCountNewText =
        newTextWidth > 0 ? (containerWidth / newTextWidth).ceil() : 1;

    textBuffer = List.filled(minRepeatCountOldText, oldText) +
        List.filled(minRepeatCountNewText * loopsToFill, newText);
    posToUpdate = oldText != ''
        ? minRepeatCountOldText * oldTextWidth
        : minRepeatCountNewText * newTextWidth;

    renderedText = textBuffer.join(); // refresh scrolling text

    if (kDebugMode) {
      debugPrint(
          'xxxx updateRenderedText => offset: $offset, minRepeatCountOldText: $minRepeatCountOldText, minRepeatCountNewText: $minRepeatCountNewText,  posToUpdate: $posToUpdate, containerWidth: $containerWidth, oldTextWidth: $oldTextWidth, newTextWidth: $newTextWidth');
    }
  }

  void replaceTextBufferWithNewText() {
    textBuffer = List.filled(minRepeatCountNewText * loopsToFill, newText);
    offset = 0;
    oldText = '';
    renderedText = textBuffer.join(); // refresh scrolling text

    posToUpdate = minRepeatCountNewText * newTextWidth;

    if (kDebugMode) {
      debugPrint(
          'xxxx replaceTextBufferWithNewText => reset offset => posToUpdate: $posToUpdate');
    }
  }

  void onTick(Duration elapsed) {
    final double delta = widget.pixelsPerSecond / 60; // assuming ~60fps

    setState(() {
      offset -= delta;
      // if (kDebugMode) {
      //   debugPrint('offset: ${offset.abs()}, posToUpdate: $posToUpdate');
      // }

      if (offset.abs() >= posToUpdate) {
        replaceTextBufferWithNewText();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (containerWidth != constraints.maxWidth) {
        containerWidth = constraints.maxWidth;
        updateRenderedText();
      }
      return Container(
        padding: EdgeInsets.all(2.0),
        child: ClipRect(
          child: CustomPaint(
            painter: _UpdatableTickerTextPainter(
              text: renderedText,
              textStyle: widget.style,
              offset: offset,
            ),
          ),
        ),
      );
    });
  }
}

class _UpdatableTickerTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final double offset;

  _UpdatableTickerTextPainter({
    required this.text,
    required this.textStyle,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final span = TextSpan(text: text, style: textStyle);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    canvas.translate(offset, 0);
    tp.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _UpdatableTickerTextPainter oldDelegate) =>
      text != oldDelegate.text || offset != oldDelegate.offset;
}
