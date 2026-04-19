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
    return SizedBox(
      child: Center(
        child: RadioGroup<String>(
          groupValue: selectedOption,
          onChanged: (String? value) {
            setState(() => selectedOption = value ?? '');
            if (value != null) {
              widget.onChanged(value);
            }
          },
          child: Globals.inMacosStyle() || Globals.inIosStyle()
              ? Column(
                  children: <Widget>[
                    ...widget.options.map(
                      (String el) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),

                        child: Row(
                          children: [
                            CupertinoRadio<String>(value: el),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  el,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: ColorDefs.textColor(
                                      context: context,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: <Widget>[
                    ...widget.options.map(
                      (String el) => Row(
                        children: [
                          Radio<String>(value: el),
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
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
