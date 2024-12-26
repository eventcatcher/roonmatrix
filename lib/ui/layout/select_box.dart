import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/roonmatrix_styles.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SelectBox extends StatefulWidget {
  final bool showMacStyle;
  final Map<String, dynamic> translations;
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
    required this.showMacStyle,
    required this.translations,
    required this.options,
    this.aligned,
    this.label,
    this.labelColor,
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

  int selectedItem = -1;

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

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  Widget dropdownElement({required bool expanded}) {
    if (Platform.isIOS) {
      return widget.options!.keys.toList().isEmpty
          ? Text(widget.translations['zonePickerOptionsEmpty'] ?? 'none')
          : CupertinoButton(
              child: Text(
                widget.selected != null
                    ? widget.selected!
                    : widget.translations['zonePickerSelectionEmpty'] ??
                        'Please Select',
              ),
              onPressed: () => _showDialog(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CupertinoButton(
                          child: Text(
                              widget.translations['dialogCancelButtonText'] ??
                                  'Cancel'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: SizedBox(),
                        ),
                        CupertinoButton(
                          child:
                              Text(widget.translations['okButtonText'] ?? 'OK'),
                          onPressed: () {
                            widget.onChanged(widget.options!.keys.toList()[
                                selectedItem >= 0 ? selectedItem : 0]);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        magnification: 1.22,
                        squeeze: 1.2,
                        useMagnifier: true,
                        itemExtent: 48,
                        scrollController: FixedExtentScrollController(
                          initialItem: widget.selected != null
                              ? widget.options!.keys
                                  .toList()
                                  .indexOf(widget.selected!)
                              : 0,
                        ),
                        onSelectedItemChanged: (int index) {
                          selectedItem = index;
                        },
                        children: List<Widget>.generate(widget.options!.length,
                            (int index) {
                          return Center(
                            child: Text(
                              widget.options!.keys.toList()[index],
                              style: TextStyle(fontSize: 13.0),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
    }

    return widget.showMacStyle == true && Platform.isMacOS
        ? MacosPopupButton<String>(
            value: widget.selected,
            onChanged: (String? value) {
              widget.onChanged(value);
            },
            items: (widget.options != null && widget.options!.isNotEmpty)
                ? widget.options!.keys
                    .map<MacosPopupMenuItem<String>>((String key) {
                    return MacosPopupMenuItem<String>(
                      value: key,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: widget.optionsWithVerticalSpace == true
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
          )
        : DropdownButton<String>(
            value: widget.selected,
            isExpanded: expanded,
            hint: widget.placeholder != null
                ? Text(
                    widget.placeholder!,
                    style: TextStyle(
                      color: SharedWidgets.textColor(
                          showMacStyle: widget.showMacStyle, context: context),
                      fontSize: 12.0,
                    ),
                  )
                : null,
            //dropdownColor: Colors.white,
            icon: Icon(
              Icons.arrow_drop_down,
              color: SharedWidgets.iconColor(
                  showMacStyle: widget.showMacStyle, context: context),
            ),
            iconSize: 32,
            elevation: 16,
            style: TextStyle(
              color: SharedWidgets.textColor(
                  showMacStyle: widget.showMacStyle, context: context),
            ),
            underline: Container(
              height: 0,
              color: Colors.blue,
            ),
            onChanged: (String? value) {
              widget.onChanged(value);
            },
            items: (widget.options != null && widget.options!.isNotEmpty)
                ? (widget.options!.keys
                    .map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: widget.optionsWithVerticalSpace == true
                                ? 8.0
                                : 0.0),
                        child: Text(
                          key,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    );
                  }).toList())
                : [],
          );
  }

  Widget dropdownReadonlyElement() {
    return Container(
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
              : SharedWidgets.textColor(
                  showMacStyle: widget.showMacStyle, context: context),
          fontSize: 13.0,
        ),
      ),
    );
  }

  Widget dropdown({required bool expanded}) => Container(
        height: Platform.isIOS ? 56.0 : 36.0,
        padding: widget.showMacStyle && Platform.isMacOS
            ? null
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: widget.showMacStyle && Platform.isMacOS
            ? null
            : RoonmatrixStyles.boxDecoration(
                fillColor: SharedWidgets.elementBackgroundColor(
                    showMacStyle: widget.showMacStyle, context: context)),
        child: widget.readOnly == true
            ? dropdownReadonlyElement()
            : dropdownElement(expanded: expanded),
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
                      style: TextStyle(
                        color: SharedWidgets.textColor(
                            showMacStyle: widget.showMacStyle,
                            context: context),
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
                        color: widget.labelColor ??
                            SharedWidgets.textColor(
                                showMacStyle: widget.showMacStyle,
                                context: context),
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
