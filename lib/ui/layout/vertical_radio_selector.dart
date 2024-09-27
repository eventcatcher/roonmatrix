import 'package:flutter/material.dart';

class VerticalRadioSelector extends StatefulWidget {
  final List<String> options;
  final String? selectedOption;
  final void Function(String value) onChanged;

  const VerticalRadioSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  State<VerticalRadioSelector> createState() => _VerticalRadioSelectorState();
}

class _VerticalRadioSelectorState extends State<VerticalRadioSelector> {
  String selectedOption = '';

  @override
  void initState() {
    selectedOption = widget.selectedOption ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = widget.options
        .map((String el) => ListTile(
            contentPadding: const EdgeInsets.all(0),
            horizontalTitleGap: 0,
            title: Text(
              el,
              style: const TextStyle(fontSize: 12.0),
            ),
            leading: SizedBox(
              width: 20.0,
              child: Radio<String>(
                value: el,
                groupValue: selectedOption,
                onChanged: (String? value) {
                  setState(() {
                    selectedOption = value ?? '';
                  });
                  if (value != null) {
                    widget.onChanged(el);
                  }
                },
              ),
            ),
            onTap: () {
              setState(() {
                selectedOption = el;
              });
              widget.onChanged(el);
            }) as Widget)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
