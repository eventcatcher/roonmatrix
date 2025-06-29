import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class UpdatableTicker extends StatefulWidget {
  final String updatableText; // text (updatable from parent)
  final TextStyle style; // text fontFamily, size, and color
  final double
      pixelsPerSecond; // speed in pixels per second (60 frames per second)
  final bool
      forceUpdate; // true: if a text is updated, display it without delay, false: integrate new text smoothly into ticker without causing disruptions when scrolling
  final bool center; // true: vertical centering of text
  final String
      separator; // add this text to the end of line as separator between texts

  const UpdatableTicker({
    required this.updatableText,
    required this.style,
    this.pixelsPerSecond = 30.0,
    this.forceUpdate = false,
    this.center = false,
    this.separator = '',
    super.key,
  });

  @override
  State<UpdatableTicker> createState() => _UpdatableTickerState();
}

class _UpdatableTickerState extends State<UpdatableTicker>
    with SingleTickerProviderStateMixin {
  final int loopsToFill = 3;
  final double securitySecSpacing =
      3; // minimum of seconds before new text starts

  List nextUpdateProperties = [];
  String firstText = '';
  String secondText = '';
  String renderedText = '';

  double securityPxSpacing = 50;
  double containerWidth = 0.0;
  double textHeight = 30.0;
  double secondTextWidth = 0.0;
  double posToUpdate = 0.0;
  double posSecondTextStarts = -1;
  double offset = 0.0;

  int minRepeatCountSecondText = 1;

  late final Ticker ticker;

  @override
  void initState() {
    super.initState();

    firstText = '';
    secondText = widget.updatableText + widget.separator;
    ticker = Ticker(onTick)..start();
  }

  @override
  void didUpdateWidget(UpdatableTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (containerWidth > 0) {
      refreshSecuritySpacing();
      textUpdateReceived();
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void refreshSecuritySpacing() {
    securityPxSpacing = widget.pixelsPerSecond * securitySecSpacing;
    if (securityPxSpacing > containerWidth / 3) {
      securityPxSpacing = containerWidth /
          3; // max security spacing is third of container width (to have enough time to pre-generate rendering data)
    }
  }

  void textUpdateReceived() {
    if ((widget.updatableText + widget.separator) != secondText) {
      if (widget.forceUpdate == true) {
        firstText = '';
        secondText = widget.updatableText + widget.separator;
        List updateProperties = updateRenderDataList(withOffset: false);
        updateRenderingProperties(updateProperties);
        replaceTextBufferWithNewText();
      } else {
        bool firstTextIsEmpty = firstText.isEmpty;

        if (firstTextIsEmpty) {
          firstText = secondText;
        }
        String secondTextBeforeUpdate = secondText;
        secondText = widget.updatableText + widget.separator;

        bool secondTextVisible =
            offset.abs() >= (posSecondTextStarts - securityPxSpacing);
        if (firstTextIsEmpty == true ||
            (!firstTextIsEmpty &&
                posSecondTextStarts >= 0 &&
                !secondTextVisible)) {
          List updateProperties = updateRenderDataList();
          updateRenderingProperties(updateProperties);

          if (kDebugMode) {
            debugPrint(
                'UpdatableTicker => new text received (std) => generate var updates + set @ ${DateTime.now().toLocal()} => firstTextIsEmpty: $firstTextIsEmpty, offset: ${offset.abs()}, posSecondTextStarts: $posSecondTextStarts, posToUpdate: $posToUpdate, secondTextVisible: $secondTextVisible, secondText: $secondText');
          }
        } else {
          // If firstText and secondText are running, then it's only possible to replace secondText with the new text and re-render it directly, as long as no part of the new text is visible.
          // If part of the secondText is already visible, it's required to wait for the switch until only secondText is displayed (set firstText = ‘’).
          // For this, nextUpdateProperties will contain the prepared rendering variables.

          firstText = secondTextBeforeUpdate;
          nextUpdateProperties = updateRenderDataList(withOffset: false);

          if (kDebugMode) {
            debugPrint(
                'UpdatableTicker => new text for early var preparation received @ ${DateTime.now().toLocal()} => offset: ${offset.abs()}, posSecondTextStarts: $posSecondTextStarts, secondTextVisible: $secondTextVisible, posToUpdate: ${nextUpdateProperties[2]}, next secondText: ${nextUpdateProperties[0]}, ');
          }
        }
      }
    }
  }

  void updateRenderingProperties(List updateProperties) {
    renderedText = updateProperties[1];
    posToUpdate = updateProperties[2];
    posSecondTextStarts = updateProperties[3];
    minRepeatCountSecondText = updateProperties[4];
    secondTextWidth = updateProperties[5];

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
    double firstTextWidth = measureTextSize(text: firstText);
    double preparedSecondTextWidth = measureTextSize(text: secondText);

    int minRepeatCountFirstText = firstTextWidth > 0
        ? (((withOffset ? offset.abs() : 0) + containerWidth) / firstTextWidth)
            .ceil()
        : 0;
    int preparedMinRepeatCountSecondText = preparedSecondTextWidth > 0
        ? (containerWidth / preparedSecondTextWidth).ceil()
        : 1;

    List<String> textBuffer = List.filled(minRepeatCountFirstText, firstText) +
        List.filled(preparedMinRepeatCountSecondText * loopsToFill, secondText);
    double preparedPosToUpdate = firstText != ''
        ? minRepeatCountFirstText * firstTextWidth
        : preparedMinRepeatCountSecondText * preparedSecondTextWidth;
    double preparePosSecondTextStarts = firstText != ''
        ? minRepeatCountFirstText * firstTextWidth - containerWidth
        : -1;

    return [
      secondText,
      textBuffer.join(),
      preparedPosToUpdate,
      preparePosSecondTextStarts,
      preparedMinRepeatCountSecondText,
      preparedSecondTextWidth,
    ];
  }

  void replaceTextBufferWithNewText() {
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
            'UpdatableTicker =>  buffer update only with secondText part @ ${DateTime.now().toLocal()} => nextUpdateProperties isNotEmpty: ${nextUpdateProperties.isNotEmpty}, offset: ${offset.abs()}, posToUpdate: $posToUpdate');
      }
      List<String> textBuffer =
          List.filled(minRepeatCountSecondText * loopsToFill, secondText);
      offset = 0;
      firstText = '';
      renderedText = textBuffer.join();
      posToUpdate = minRepeatCountSecondText * secondTextWidth;
    }

    if (kDebugMode) {
      debugPrint(
          'UpdatableTicker =>  buffer update => reset offset + new generated posToUpdate: $posToUpdate ($minRepeatCountSecondText x $secondTextWidth)');
      debugPrint('UpdatableTicker => ---');
    }
  }

  void onTick(Duration elapsed) {
    final double delta = widget.pixelsPerSecond / 60; // assuming ~60fps

    setState(() {
      offset -= delta;

      if (offset.abs() >= posToUpdate) {
        replaceTextBufferWithNewText(); // switch on posToUpdate (position of the firstText part has disappeared and the seconText part has just arrived at the start of ticker area)
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
              'UpdatableTicker => widget build => var generating + set @ ${DateTime.now().toLocal()}, secondText: $secondText');
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
