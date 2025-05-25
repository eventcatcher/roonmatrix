import 'package:flutter/material.dart';

class UpdatableScrollBar extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double pixelsPerSecond;
  final double height;

  const UpdatableScrollBar({
    super.key,
    required this.text,
    this.style,
    this.pixelsPerSecond = 50,
    this.height = 50,
  });

  @override
  State<UpdatableScrollBar> createState() => _UpdatableScrollBarState();
}

class _UpdatableScrollBarState extends State<UpdatableScrollBar>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  AnimationController? _animationController;

  final ValueNotifier<String> _visibleTextNotifier = ValueNotifier('');
  String _oldText = '';
  String _newText = '';

  double _containerWidth = 0;
  double lastPos = -1;
  double totalWidth = 0;
  double pixelsPerSecond = 0;

  bool initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _newText = widget.text;
  }

  @override
  void didUpdateWidget(covariant UpdatableScrollBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _newText) {
      _oldText = _newText;
      _newText = widget.text;
      initialized = false;
      debugPrint('xxxx didUpdateWidget, get _newText: $_newText');
    }
    if (pixelsPerSecond != widget.pixelsPerSecond &&
        _animationController != null) {
      pixelsPerSecond = widget.pixelsPerSecond;
      final int durationMs =
          (totalWidth / widget.pixelsPerSecond * 1000).round();
      _animationController!.duration = Duration(milliseconds: durationMs);
      if (_animationController!.isAnimating) _animationController!.forward();
    }
  }

  void _startScrollWithNewText() {
    initialized = true;
    if (_animationController != null) {
      _animationController!.dispose();
      _animationController = null;
    }

    final oldTextWidth = _measureTextWidth(_oldText);
    final newTextWidth = _measureTextWidth(_newText);

    // Wiederhole alten Text bis er breiter als Container ist:
    final oldRepeatCountOne = (oldTextWidth > 0 && _containerWidth > 0)
        ? (_containerWidth / oldTextWidth).ceil()
        : 1;

    // Wiederhole neuen Text + Puffer:
    int newRepeatCountMultiple =
        (oldTextWidth == 0 && newTextWidth > 0 && _containerWidth > 0)
            ? (2.5 * _containerWidth / newTextWidth).ceil()
            : 1;
    if (newRepeatCountMultiple == 1) {
      newRepeatCountMultiple += 1;
    }
    final newRepeatCountOne = (newTextWidth > 0 && _containerWidth > 0)
        ? (_containerWidth / newTextWidth).ceil()
        : 1;

    // Sichtbarer Text = alter Text * oldRepeatCountOne + neuer Text * (newRepeatCount + Puffer)
    final visibleText = _oldText.isNotEmpty
        ? List.filled(oldRepeatCountOne, _oldText).join() +
            List.filled(newRepeatCountMultiple, _newText).join()
        : List.filled(newRepeatCountMultiple, _newText).join();

    _visibleTextNotifier.value = visibleText;

    totalWidth = _measureTextWidth(visibleText);

    final int durationMs = (totalWidth / widget.pixelsPerSecond * 1000).round();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _animationController!.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        // final double viewportDimension =
        //     _scrollController.position.viewportDimension;
        final double realContentWidth =
            maxScroll + _scrollController.position.viewportDimension;

        double nextPos = _animationController!.value * maxScroll;
        double correctedPos = nextPos / realContentWidth * totalWidth;

        // print(
        //     'xxxx nextPos: $nextPos, correctedPos: $correctedPos, newTextWidth: $newTextWidth, _containerWidth: $_containerWidth, maxScroll: $maxScroll, viewportDimension: $viewportDimension, totalWidth: $totalWidth');

        if (newTextWidth > 0 && correctedPos >= _containerWidth) {
          //print('xxxx over _containerWidth scrolled'); // 820
          double posToFillContainer = 0;
          if (_oldText.isNotEmpty && initialized == true) {
            posToFillContainer = oldTextWidth * oldRepeatCountOne;
          } else {
            posToFillContainer = newTextWidth * newRepeatCountOne;
            // print('xxxx posToFillContainer $posToFillContainer');
          }
          if (correctedPos >= posToFillContainer) {
            if (_oldText.isNotEmpty) {
              if (initialized == true) {
                _oldText = '';
                debugPrint('xxxx remove oldText');
              }
              _startScrollWithNewText();
            } else {
              debugPrint('xxxx reset _animationController');
              _animationController!.forward(from: 0);
              nextPos = 0;
            }
          }
        }

        lastPos = nextPos;

        _scrollController.jumpTo(nextPos);
      }
    });

    debugPrint(
        'xxxx _startScrollWithNewText, _containerWidth: $_containerWidth, totalWidth: $totalWidth, durationMs: $durationMs, oldTextWidth: $oldTextWidth, oldRepeatCountOne: $oldRepeatCountOne, newTextWidth: $newTextWidth, newRepeatCountOne: $newRepeatCountOne, visibleText(len): ${visibleText.length}');

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Fallback if scrolling is freezed and therefore completed: restart scrollbar
        debugPrint('xxxx restart Scrollbar if freezed (completed)');
        _oldText = '';
        initialized = false;
        _startScrollWithNewText();
      }
    });

    _animationController!.forward(from: 0);
  }

  double _measureTextWidth(String text) {
    if (text.isEmpty) return 0;

    final TextScaler textScaler = MediaQuery.of(context).textScaler;

    final tp = TextPainter(
      text: TextSpan(text: text, style: widget.style ?? const TextStyle()),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    // debugPrint(
    //     'yyyy _measureTextWidth: ${tp.width}, textlen: ${text.length}, text: $text');
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_containerWidth != constraints.maxWidth) {
        _containerWidth = constraints.maxWidth;

        // Starte Scroll wenn Breite bekannt und Text initialisiert ist
        if (_animationController == null && _newText.isNotEmpty) {
          _oldText = '';
          _startScrollWithNewText();
        }
      }

      return SizedBox(
        width: _containerWidth,
        height: widget.height,
        child: ClipRect(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _visibleTextNotifier,
                builder: (context, text, _) {
                  return Text(
                    text,
                    style: widget.style,
                    softWrap: false,
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    _visibleTextNotifier.dispose();
    super.dispose();
  }
}
