import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';

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
        .map((String el) => Row(
              children: [
                SizedBox(
                  width: 20.0,
                  child: Center(
                    child: Globals.inMacosStyle() || Globals.inIosStyle()
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: CupertinoRadio(
                              value: el,
                              groupValue: selectedOption,
                              onChanged: (String? value) {
                                setState(() => selectedOption = value ?? '');
                                if (value != null) {
                                  widget.onChanged(el);
                                }
                              },
                            ),
                          )
                        : Radio<String>(
                            value: el,
                            groupValue: selectedOption,
                            onChanged: (String? value) {
                              setState(() => selectedOption = value ?? '');
                              if (value != null) {
                                widget.onChanged(el);
                              }
                            },
                          ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      el,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: ColorDefs.textColor(context: context),
                      ),
                    ),
                  ),
                ),
              ],
            ) as Widget)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
