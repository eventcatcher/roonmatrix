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
      height: 300.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5)),
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
                    style: const TextStyle(
                        fontSize: 16.0, fontWeight: FontWeight.bold),
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
