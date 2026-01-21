import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class DebugMessageCard extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String logMessage;

  const DebugMessageCard({
    super.key,
    required this.translations,
    required this.logMessage,
  });

  @override
  State<DebugMessageCard> createState() => DebugMessageCardState();
}

class DebugMessageCardState extends State<DebugMessageCard> {
  Map<String, dynamic> get translations => widget.translations;

  final double cardHeight = 300.0;
  final double fontSize = 16.0;

  late String logMessage;

  @override
  void initState() {
    logMessage = widget.logMessage;
    super.initState();
  }

  @override
  void didUpdateWidget(DebugMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    logMessage = widget.logMessage;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: SharedWidgets.borderRadius(),
          ),
          color: Colors.lightBlueAccent,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    translations['debugMessage'] ?? 'Debug Messages:',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Text(logMessage),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
