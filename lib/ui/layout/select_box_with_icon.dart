import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SelectBoxWithIcon extends StatefulWidget {
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
  Map<String, dynamic> get translations => widget.translations;
  Map<String, dynamic>? get options => widget.options;
  String? get aligned => widget.aligned;
  String? get label => widget.label;
  Color? get labelColor => widget.labelColor;
  String? get placeholder => widget.placeholder;
  String? get selected => widget.selected;
  bool? get inRow => widget.inRow;
  bool? get noVerticalSpace => widget.noVerticalSpace;
  bool? get readOnly => widget.readOnly;
  bool? get optionsWithVerticalSpace => widget.optionsWithVerticalSpace;
  void Function(String? value) get onChanged => widget.onChanged;

  final double fontSize = 16.0;
  final double timeIconSize = 16.0;

  int selectedItem = -1;
  BuildContext? modalContext;

  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    switch (aligned) {
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

  Widget dropdownReadonlyElement({
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        (options != null && selected != null && options![selected!] != null)
            ? options![selected]['name']!
            : "",
        style: TextStyle(
          color: ColorDefs.textColor(context: context),
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget dropdownElement({
    required BuildContext context,
    required bool expanded,
  }) {
    if (Globals.inIosStyle()) {
      return options!.keys.toList().isEmpty
          ? Text(translations['zonePickerOptionsEmpty'] ?? 'none')
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
                color: ColorDefs.elementBackgroundColor(context: context),
                borderRadius: Globals.borderRadius(),
              ),
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
                        size: timeIconSize,
                        color: ColorDefs.iconColor(context: context),
                      ),
                    ),
                    Text(
                      selected != null
                          ? options!.values.toList()[
                              options!.keys.toList().indexOf(selected!)]['name']
                          : translations['zonePickerSelectionEmpty'] ??
                              'Please Select',
                    ),
                  ],
                ),
                onPressed: () => options != null
                    ? SharedWidgets.showIosPickerDialog(
                        translations: translations,
                        context: context,
                        options: options!,
                        selected: selected,
                        showValue: true,
                        isObject: true,
                        onApproved: () => onChanged(options!.keys
                            .toList()[selectedItem >= 0 ? selectedItem : 0]),
                        onSelectedItemChanged: (int index) {
                          selectedItem = index;
                        },
                      )
                    : null,
              ),
            );
    }

    return Globals.selectBoxInMacStyle()
        ? SizedBox(
            child: MacosPopupButton<String>(
              value: selected,
              onChanged: (String? value) {
                onChanged(value);
              },
              selectedItemBuilder: (context) => options!.keys
                  .map(
                    (String key) => Row(
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: 6.0),
                          child: Icon(
                            CupertinoIcons.time,
                            size: timeIconSize,
                            color: ColorDefs.iconColor(context: context),
                          ),
                        ),
                        Text(
                          options![key]['name'],
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                              color: ColorDefs.textColor(context: context),
                              fontSize: fontSize,
                              decorationStyle: TextDecorationStyle.double),
                        ),
                      ],
                    ),
                  )
                  .toList(),
              items: (options != null && options!.isNotEmpty)
                  ? options!.keys
                      .map<MacosPopupMenuItem<String>>(
                        (String key) => MacosPopupMenuItem<String>(
                          value: key,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: optionsWithVerticalSpace == true
                                    ? 8.0
                                    : 0.0),
                            child: Text(
                              options![key]['name'],
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                  color: ColorDefs.textColor(context: context),
                                  fontSize: fontSize,
                                  decorationStyle: TextDecorationStyle.double),
                            ),
                          ),
                        ),
                      )
                      .toList()
                  : [],
            ),
          )
        : DropdownButtonFormField<String>(
            value: selected,
            decoration: InputDecoration(
              prefixIconConstraints: BoxConstraints(
                minWidth: 16.0,
                minHeight: 32.0,
              ),
              prefixIcon: Padding(
                padding: EdgeInsetsDirectional.only(end: 6.0),
                child: Icon(
                  CupertinoIcons.time,
                  size: timeIconSize,
                  color: ColorDefs.iconColor(context: context),
                ),
              ),
              contentPadding: EdgeInsets.only(bottom: 11.0),
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            isExpanded: expanded,
            hint: placeholder != null
                ? Text(
                    placeholder!,
                    style: TextStyle(
                      color: ColorDefs.textColor(context: context),
                      fontSize: fontSize,
                    ),
                  )
                : null,
            dropdownColor: ColorDefs.selectboxBackgroundColor(context: context),
            icon: Container(
              padding: EdgeInsets.only(
                  bottom: 11.0, right: Platform.isAndroid ? 8 : 4),
              transform: Platform.isAndroid
                  ? Matrix4.translationValues(0, -2.0, 0.0)
                  : null,
              child: Icon(
                Icons.arrow_drop_down,
                color: ColorDefs.iconColor(context: context),
                size: 32,
                opticalSize: 32,
              ),
            ),
            iconSize: 32,
            elevation: 16,
            style: TextStyle(
              color: ColorDefs.textColor(context: context), // option text color
            ),
            onChanged: (String? value) {
              onChanged(value);
            },
            items: (options != null && options!.isNotEmpty)
                ? options!.keys.map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Row(
                        children: [
                          if (options![key]['icon'] != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(options![key]['icon'], size: 19.0),
                            ),
                          Text(
                            options![key]['name'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: (TextStyle(
                                color: ColorDefs.textColor(context: context),
                                fontSize: fontSize,
                                fontWeight: options![key]['fontWeight'] ??
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
        height: Globals.inIosStyle()
            ? 56.0
            : Globals.selectBoxInMacStyle()
                ? null
                : 36.0,
        margin: EdgeInsets.only(top: 4),
        padding: Globals.inIosStyle() || (Globals.selectBoxInMacStyle())
            ? null
            : const EdgeInsets.only(left: 10),
        decoration: Globals.inIosStyle() || (Globals.selectBoxInMacStyle())
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
                color: ColorDefs.elementBackgroundColor(context: context),
                borderRadius: Globals.borderRadius(),
              ),
        child: readOnly == true
            ? dropdownReadonlyElement(context: context)
            : dropdownElement(context: context, expanded: expanded),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: Alignment.topLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: noVerticalSpace == true ? 0 : 10),
        child: inRow != null && inRow == true
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        color: ColorDefs.textColor(context: context),
                        fontSize: fontSize,
                      ),
                    ),
                  dropdown(expanded: false),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(
                      label!,
                      style: TextStyle(
                        color:
                            labelColor ?? ColorDefs.textColor(context: context),
                        fontSize: fontSize,
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
}
