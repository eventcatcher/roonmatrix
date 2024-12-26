import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SelectBoxWithIcon extends StatefulWidget {
  final bool showMacStyle;
  final Map<String, dynamic> translations;
  final Map<String, dynamic>? options;
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final String? selected;
  final bool? inRow;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final bool? optionsWithVerticalSpace;
  final void Function(String? value) onChanged;

  const SelectBoxWithIcon({
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
    this.optionsWithVerticalSpace,
    required this.onChanged,
  });

  @override
  SelectBoxWithIconState createState() => SelectBoxWithIconState();
}

class SelectBoxWithIconState extends State<SelectBoxWithIcon> {
  late EdgeInsetsGeometry margin;

  int selectedItem = -1;
  bool showInMacStylePossible = true;

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

  Widget dropdownReadonlyElement() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        (widget.options != null &&
                widget.selected != null &&
                widget.options![widget.selected!] != null)
            ? widget.options![widget.selected]['name']!
            : "",
        style: TextStyle(
          color: SharedWidgets.textColor(
              showMacStyle: widget.showMacStyle, context: context),
          fontSize: 16.0,
        ),
      ),
    );
  }

  Widget dropdownElement({required bool expanded}) {
    if (Platform.isIOS) {
      return widget.options!.keys.toList().isEmpty
          ? Text(widget.translations['zonePickerOptionsEmpty'] ?? 'none')
          : Container(
              decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      offset: Offset(0.1, 0.5),
                      blurRadius: 0.1,
                      blurStyle: BlurStyle.normal,
                    )
                  ],
                  color: SharedWidgets.elementBackgroundColor(
                      showMacStyle: widget.showMacStyle, context: context),
                  borderRadius: const BorderRadius.all(Radius.circular(4))),
              child: CupertinoButton(
                padding: EdgeInsets.only(
                  left: 8.0,
                  top: 10.0,
                  right: 18.0,
                  bottom: 10.0,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 6.0),
                      child: Icon(
                        CupertinoIcons.time,
                        size: 16.0,
                        color: SharedWidgets.iconColor(
                            showMacStyle: widget.showMacStyle,
                            context: context),
                      ),
                    ),
                    Text(
                      widget.selected != null
                          ? widget.options!.values.toList()[widget.options!.keys
                              .toList()
                              .indexOf(widget.selected!)]['name']
                          : widget.translations['zonePickerSelectionEmpty'] ??
                              'Please Select',
                    ),
                  ],
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
                            child: Text(
                                widget.translations['okButtonText'] ?? 'OK'),
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
                                ? widget.options!.values
                                    .toList()
                                    .indexOf(widget.selected!)
                                : 0,
                          ),
                          onSelectedItemChanged: (int index) {
                            selectedItem = index;
                          },
                          children: List<Widget>.generate(
                              widget.options!.length, (int index) {
                            return Center(
                              child: Text(
                                widget.options!.values.toList()[index]['name'],
                                style: TextStyle(fontSize: 16.0),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
    }

    return showInMacStylePossible == true &&
            widget.showMacStyle == true &&
            Platform.isMacOS
        ? SizedBox(
            // width: double.infinity,
            child: MacosPopupButton<String>(
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
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.only(end: 6.0),
                                child: Icon(
                                  CupertinoIcons.time,
                                  size: 16.0,
                                  color: SharedWidgets.iconColor(
                                      showMacStyle: widget.showMacStyle,
                                      context: context),
                                ),
                              ),
                              Text(
                                widget.options![key]['name'],
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                    color: SharedWidgets.textColor(
                                        showMacStyle: widget.showMacStyle,
                                        context: context),
                                    fontSize: 16.0,
                                    decorationStyle:
                                        TextDecorationStyle.double),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()
                  : [],
            ),
          )
        : DropdownButtonFormField<String>(
            value: widget.selected,
            decoration: InputDecoration(
              prefixIconConstraints: BoxConstraints(
                minWidth: 16.0,
                minHeight: 36.0,
              ),
              prefixIcon: Padding(
                padding: EdgeInsetsDirectional.only(end: 6.0),
                child: Icon(
                  CupertinoIcons.time,
                  size: 16.0,
                  color: SharedWidgets.iconColor(
                      showMacStyle: widget.showMacStyle, context: context),
                ),
              ),
              contentPadding: EdgeInsets.zero,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            isExpanded: expanded,
            hint: widget.placeholder != null
                ? Text(
                    widget.placeholder!,
                    style: TextStyle(
                      color: SharedWidgets.textColor(
                          showMacStyle: widget.showMacStyle, context: context),
                      fontSize: 16.0,
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
                  showMacStyle: widget.showMacStyle,
                  context: context), // option text color
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
                                fontSize: 16.0,
                                fontWeight: widget.options![key]
                                        ['fontWeight'] ??
                                    FontWeight.normal)),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                : [],
          );
  }

  Widget dropdown({required bool expanded}) => Container(
        height: Platform.isIOS ? 56.0 : 36.0,
        padding: Platform.isIOS ||
                (showInMacStylePossible == true &&
                    widget.showMacStyle == true &&
                    Platform.isMacOS)
            ? null
            : const EdgeInsets.only(left: 10),
        decoration: Platform.isIOS ||
                (showInMacStylePossible == true &&
                    widget.showMacStyle == true &&
                    Platform.isMacOS)
            ? null
            : BoxDecoration(
                boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      offset: Offset(0.1, 0.5),
                      blurRadius: 0.1,
                      blurStyle: BlurStyle.normal,
                    )
                  ],
                color: SharedWidgets.elementBackgroundColor(
                    showMacStyle: widget.showMacStyle, context: context),
                borderRadius: const BorderRadius.all(Radius.circular(4))),
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
                        fontSize: 16.0,
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
                        fontSize: 16.0,
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
