import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SelectBoxWithIcon extends StatefulWidget {
  final Map<String, dynamic>? options;
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final String? selected;
  final bool? inRow;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final void Function(String? value) onChanged;

  const SelectBoxWithIcon({
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
    required this.onChanged,
  });

  @override
  SelectBoxWithIconState createState() => SelectBoxWithIconState();
}

class SelectBoxWithIconState extends State<SelectBoxWithIcon> {
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
        margin = const EdgeInsets.only(left: 8.0, right: 8.0);
        break;
      case "horizontalSmallBottom":
        margin = const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0);
        break;
      case "inline":
        margin = const EdgeInsets.all(0);
        break;
      default:
        margin =
            const EdgeInsets.only(left: 8.0, right: 8.0, top: 2.0, bottom: 0.0);
    }
    super.initState();
  }

  Widget dropdown({required bool expanded}) => Container(
        height: 36.0,
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.1, 0.5),
                blurRadius: 0.1,
                blurStyle: BlurStyle.normal,
              )
            ],
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(4))),
        child: widget.readOnly == true
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  (widget.options != null &&
                          widget.selected != null &&
                          widget.options![widget.selected!] != null)
                      ? widget.options![widget.selected]['name']!
                      : "",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 19.0,
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                value: widget.selected,
                decoration: const InputDecoration(
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 16.0,
                    minHeight: 36.0,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 16.0),
                    child: Icon(CupertinoIcons.time, size: 16.0),
                  ),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                isExpanded: expanded,
                hint: widget.placeholder != null
                    ? Text(
                        widget.placeholder!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 19.0,
                        ),
                      )
                    : null,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 32,
                elevation: 16,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
                onChanged: (String? value) {
                  widget.onChanged(value);
                },
                items: (widget.options != null && widget.options!.isNotEmpty)
                    ? widget.options!.keys
                        .map<DropdownMenuItem<String>>((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Row(
                            children: [
                              if (widget.options![key]['icon'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(widget.options![key]['icon'],
                                      size: 19.0),
                                ),
                              Text(
                                widget.options![key]['name'],
                                overflow: TextOverflow.fade,
                                style: (TextStyle(
                                    fontSize: 19.0,
                                    fontWeight: widget.options![key]
                                            ['fontWeight'] ??
                                        FontWeight.normal)),
                              ),
                            ],
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
                        fontSize: 19.0,
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
                        fontSize: 19.0,
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
