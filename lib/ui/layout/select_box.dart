import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/roonmatrix_styles.dart';

class SelectBox extends StatefulWidget {
  final Map<String, String>? options;
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final String? selected;
  final bool? inRow;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final bool? readOnlyColoredGrey;
  final bool? optionsWithVerticalSpace;
  final void Function(String? value) onChanged;

  const SelectBox({
    super.key,
    required this.options,
    this.aligned,
    this.label,
    this.labelColor = Colors.black,
    this.placeholder,
    this.selected,
    this.inRow,
    this.noVerticalSpace,
    this.readOnly,
    this.readOnlyColoredGrey = false,
    this.optionsWithVerticalSpace,
    required this.onChanged,
  });

  @override
  SelectBoxState createState() => SelectBoxState();
}

class SelectBoxState extends State<SelectBox> {
  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    switch (widget.aligned) {
      case "left":
        margin = const EdgeInsets.only(
            left: 16.0, right: 8.0, top: 16.0, bottom: 5.0);
        break;
      case "right":
        margin = const EdgeInsets.only(
            left: 8.0, right: 16.0, top: 16.0, bottom: 5.0);
        break;
      case "leftSmallBottom":
        margin = const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 5.0);
        break;
      case "rightSmallBottom":
        margin = const EdgeInsets.only(left: 8.0, right: 16.0, bottom: 5.0);
        break;
      case "horizontal":
        margin = const EdgeInsets.only(left: 16.0, right: 16.0);
        break;
      case "horizontalSmallBottom":
        margin = const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0);
        break;
      case "inline":
        margin = const EdgeInsets.all(0);
        break;
      default:
        margin = const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 16.0, bottom: 5.0);
    }
    super.initState();
  }

  Widget dropdown({required bool expanded}) => Container(
        height: 36.0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: RoonmatrixStyles.boxDecoration,
        child: widget.readOnly == true
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  (widget.options != null &&
                          widget.selected != null &&
                          widget.options![widget.selected!] != null)
                      ? widget.selected!
                      : "",
                  style: TextStyle(
                    color: widget.readOnlyColoredGrey == true
                        ? Colors.grey
                        : Colors.black,
                    fontSize: 13.0,
                  ),
                ),
              )
            : DropdownButton<String>(
                value: widget.selected,
                isExpanded: expanded,
                hint: widget.placeholder != null
                    ? Text(
                        widget.placeholder!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12.0,
                        ),
                      )
                    : null,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 32,
                elevation: 16,
                style: TextStyle(color: Colors.grey.shade700),
                underline: Container(
                  height: 0,
                  color: Colors.blue,
                ),
                onChanged: (String? value) {
                  widget.onChanged(value);
                },
                items: (widget.options != null && widget.options!.isNotEmpty)
                    ? widget.options!.keys
                        .map<DropdownMenuItem<String>>((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical:
                                    widget.optionsWithVerticalSpace == true
                                        ? 8.0
                                        : 0.0),
                            child: Text(
                              key,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        );
                      }).toList()
                    : [],
              ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: Alignment.topLeft,
      child: Container(
        margin:
            EdgeInsets.only(bottom: widget.noVerticalSpace == true ? 0 : 10),
        child: widget.inRow != null && widget.inRow == true
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12.0,
                      ),
                    ),
                  dropdown(expanded: false),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.label != null) ...[
                    Text(
                      widget.label!,
                      style: TextStyle(
                        color: widget.labelColor,
                        fontSize: 12.0,
                      ),
                    ),
                    const SizedBox(
                      height: 4.0,
                    ),
                  ],
                  dropdown(expanded: true),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
