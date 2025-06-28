import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class UpdatableTicker extends StatefulWidget {
  final String newText;
  final TextStyle style;
  final bool center;

  final double pixelsPerSecond;

  const UpdatableTicker({
    required this.newText,
    required this.style,
    required this.center,
    this.pixelsPerSecond = 30.0,
    super.key,
  });

  @override
  State<UpdatableTicker> createState() => _UpdatableTickerState();
}

class _UpdatableTickerState extends State<UpdatableTicker>
    with SingleTickerProviderStateMixin {
  final int loopsToFill = 3;
  final double securitySecSpacing =
      3; // minimum of 3 seconds before new text starts

  List nextUpdateProperties = [];
  String oldText = '';
  String newText = '';
  String renderedText = '';

  double securityPxSpacing = 50;
  double containerWidth = 0.0;
  double textHeight = 30.0;
  double newTextWidth = 0.0;
  double posToUpdate = 0.0;
  double posNewTextStarts = -1;
  double offset = 0.0;

  int minRepeatCountNewText = 1;

  late final Ticker ticker;

  @override
  void initState() {
    super.initState();
    oldText = '';
    newText = widget.newText;
    ticker = Ticker(onTick)..start();
  }

  @override
  void didUpdateWidget(UpdatableTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    securityPxSpacing = widget.pixelsPerSecond * 3;
    if (securityPxSpacing > containerWidth / 3) {
      securityPxSpacing = containerWidth / 3;
    }

    if (widget.newText != newText) {
      bool oldTextIsEmpty = oldText.isEmpty;

      if (oldTextIsEmpty) {
        oldText = newText;
      }
      String newTextBeforeUpdate = newText;
      newText = widget.newText;

      if (containerWidth > 0) {
        bool newTextVisible =
            offset.abs() >= (posNewTextStarts - securityPxSpacing);
        if (oldTextIsEmpty == true ||
            (!oldTextIsEmpty && posNewTextStarts >= 0 && !newTextVisible)) {
          List updateProperties = updateRenderDataList();
          updateRenderingProperties(updateProperties);

          if (kDebugMode) {
            debugPrint(
                'UpdatableTicker => new text received (std) => generate var updates + set @ ${DateTime.now().toLocal()} => oldTextIsEmpty: $oldTextIsEmpty, offset: ${offset.abs()}, posNewTextStarts: $posNewTextStarts, posToUpdate: $posToUpdate, newTextVisible: $newTextVisible, newText: $newText');
          }
        } else {
          // Wenn oldText und newText laufen, dann kann man (NUR) newText durch den neuen Text austauschen und direkt neu rendern,
          // solange noch kein Teil des neuen Textes sichtbar ist.
          // Sollte ein Teil des neuen Textes bereits sichtbar sein, dann muss man den Switch abwarten bis nur noch newText angezeigt wird (set oldText = '').
          // Dafür wird nextUpdateProperties verwendet, welcher den newText + veryNewTest vorher vorgerendert hat.

          oldText = newTextBeforeUpdate;
          nextUpdateProperties = updateRenderDataList(withOffset: false);

          if (kDebugMode) {
            debugPrint(
                'UpdatableTicker => new text received (early preparation) @ ${DateTime.now().toLocal()} => offset: ${offset.abs()}, posNewTextStarts: $posNewTextStarts, newTextVisible: $newTextVisible, posToUpdate: ${nextUpdateProperties[2]}, next newText: ${nextUpdateProperties[0]}, ');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void updateRenderingProperties(List updateProperties) {
    //newText = updateProperties[0];
    renderedText = updateProperties[1];
    posToUpdate = updateProperties[2];
    posNewTextStarts = updateProperties[3];
    minRepeatCountNewText = updateProperties[4];
    newTextWidth = updateProperties[5];

    nextUpdateProperties = [];
  }

  double measureTextSize({required String text, bool vertical = false}) {
    if (text.isEmpty) return 0;

    final TextScaler textScaler = MediaQuery.of(context).textScaler;

    final tp = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    return vertical ? tp.height : tp.width;
  }

  List updateRenderDataList({bool withOffset = true}) {
    double oldTextWidth = measureTextSize(text: oldText);
    double preparedNewTextWidth = measureTextSize(text: newText);

    int minRepeatCountOldText = oldTextWidth > 0
        ? (((withOffset ? offset.abs() : 0) + containerWidth) / oldTextWidth)
            .ceil()
        : 0;
    int preparedMinRepeatCountNewText = preparedNewTextWidth > 0
        ? (containerWidth / preparedNewTextWidth).ceil()
        : 1;

    List<String> textBuffer = List.filled(minRepeatCountOldText, oldText) +
        List.filled(preparedMinRepeatCountNewText * loopsToFill, newText);
    double preparedPosToUpdate = oldText != ''
        ? minRepeatCountOldText * oldTextWidth
        : preparedMinRepeatCountNewText * preparedNewTextWidth;
    double preparePosNewTextStarts = oldText != ''
        ? minRepeatCountOldText * oldTextWidth - containerWidth
        : -1;

    return [
      newText,
      textBuffer.join(),
      preparedPosToUpdate,
      preparePosNewTextStarts,
      preparedMinRepeatCountNewText,
      preparedNewTextWidth,
    ];
  }

  void replaceTextBufferWithNewText() {
    // switch at posToUpdate position (position of the old text has disappeared and the first new text has just arrived at the start of ticker area)
    if (nextUpdateProperties.isNotEmpty) {
      double actualPosToUpdate = posToUpdate;
      offset = 0;
      if (containerWidth > 0) {
        updateRenderingProperties(nextUpdateProperties);
      }
      if (kDebugMode) {
        debugPrint(
            'UpdatableTicker =>  buffer update with prepared properties @ ${DateTime.now().toLocal()} => nextUpdateProperties isNotEmpty: ${nextUpdateProperties.isNotEmpty}, offset: ${offset.abs()}, actualPosToUpdate: $actualPosToUpdate, new posToUpdate: $posToUpdate');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            'UpdatableTicker =>  buffer update only with newText @ ${DateTime.now().toLocal()} => nextUpdateProperties isNotEmpty: ${nextUpdateProperties.isNotEmpty}, offset: ${offset.abs()}, posToUpdate: $posToUpdate');
      }
      List<String> textBuffer =
          List.filled(minRepeatCountNewText * loopsToFill, newText);
      offset = 0;
      oldText = '';
      renderedText = textBuffer.join(); // refresh scrolling text

      posToUpdate = minRepeatCountNewText * newTextWidth;
    }

    if (kDebugMode) {
      debugPrint(
          'UpdatableTicker =>  buffer update => reset offset + new generated posToUpdate: $posToUpdate ($minRepeatCountNewText x $newTextWidth)');
      debugPrint('UpdatableTicker => ---');
    }
  }

  void onTick(Duration elapsed) {
    final double delta = widget.pixelsPerSecond / 60; // assuming ~60fps

    setState(() {
      offset -= delta;

      if (offset.abs() >= posToUpdate) {
        replaceTextBufferWithNewText(); // switch on posToUpdate (position of the old text has disappeared and the first new text has just arrived at the start of ticker area)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (containerWidth != constraints.maxWidth) {
        containerWidth = constraints.maxWidth;
        List updateProperties = updateRenderDataList();
        updateRenderingProperties(updateProperties);
        if (kDebugMode) {
          debugPrint(
              'UpdatableTicker => widget build => var generating + set @ ${DateTime.now().toLocal()}, newText: $newText');
        }
      }

      textHeight = measureTextSize(text: 'XXX', vertical: true);

      return Container(
        padding: EdgeInsets.all(2.0),
        child: ClipRect(
          child: Align(
            alignment: widget.center ? Alignment.centerLeft : Alignment.topLeft,
            child: CustomPaint(
              painter: _UpdatableTickerTextPainter(
                text: renderedText,
                textStyle: widget.style,
                offset: offset,
                ypos: widget.center ? -textHeight / 2 : 0,
              ),
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
  final double ypos;

  _UpdatableTickerTextPainter({
    required this.text,
    required this.textStyle,
    required this.offset,
    required this.ypos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final span = TextSpan(text: text, style: textStyle);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    canvas.translate(offset, ypos);
    tp.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _UpdatableTickerTextPainter oldDelegate) =>
      text != oldDelegate.text || offset != oldDelegate.offset;
}
