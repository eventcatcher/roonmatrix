import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/roonmatrix_styles.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SelectBox extends StatefulWidget {
  final Map<String, dynamic> translations;
  final Map<String, String>? options;
  final String? aligned;
  final String? label;
  final FontWeight? labelWeight;
  final Color? labelColor;
  final double? labelFontSize;
  final String? placeholder;
  final String? selected;
  final bool? showValue;
  final bool? inRow;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final double? maxWidth;
  final bool? expanded;
  final bool? elementExpanded;
  final bool? readOnlyColoredGrey;
  final bool? optionsWithVerticalSpace;
  final void Function(String? value) onChanged;

  const SelectBox({
    super.key,
    required this.translations,
    required this.options,
    this.aligned,
    this.label,
    this.labelWeight,
    this.labelColor,
    this.labelFontSize = 12.0,
    this.placeholder,
    this.selected,
    this.showValue = false,
    this.inRow,
    this.noVerticalSpace,
    this.readOnly,
    this.maxWidth,
    this.expanded = false,
    this.elementExpanded = false,
    this.readOnlyColoredGrey = false,
    this.optionsWithVerticalSpace,
    required this.onChanged,
  });

  @override
  SelectBoxState createState() => SelectBoxState();
}

class SelectBoxState extends State<SelectBox> {
  Map<String, dynamic> get translations => widget.translations;
  Map<String, String>? get options => widget.options;
  String? get aligned => widget.aligned;
  String? get label => widget.label;
  FontWeight? get labelWeight => widget.labelWeight;
  Color? get labelColor => widget.labelColor;
  double? get labelFontSize => widget.labelFontSize;
  String? get placeholder => widget.placeholder;
  String? get selected => widget.selected;
  bool? get showValue => widget.showValue;
  bool? get inRow => widget.inRow;
  bool? get noVerticalSpace => widget.noVerticalSpace;
  bool? get readOnly => widget.readOnly;
  double? get maxWidth => widget.maxWidth;
  bool? get expanded => widget.expanded;
  bool? get elementExpanded => widget.elementExpanded;
  bool? get readOnlyColoredGrey => widget.readOnlyColoredGrey;
  bool? get optionsWithVerticalSpace => widget.optionsWithVerticalSpace;
  void Function(String? value) get onChanged => widget.onChanged;

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

  Widget dropdownReadonlyElement({
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        (options != null && selected != null && options![selected!] != null)
            ? selected!
            : "",
        style: TextStyle(
          color: readOnlyColoredGrey == true
              ? Colors.grey
              : ColorDefs.textColor(context: context),
          fontSize: 13.0,
        ),
      ),
    );
  }

  Widget dropdownElement({
    required BuildContext context,
    required bool expanded,
    required bool elementExpanded,
  }) {
    if (Globals.inIosStyle()) {
      Widget text = options!.keys.toList().isEmpty
          ? SizedBox()
          : Text(
              selected != null
                  ? showValue!
                      ? options![selected]
                      : selected!
                  : translations['zonePickerSelectionEmpty'] ?? 'Please Select',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );

      return options!.keys.toList().isEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translations['zonePickerOptionsEmpty'] ?? 'none',
                ),
              ],
            )
          : CupertinoButton(
              padding: EdgeInsets.zero,
              sizeStyle: CupertinoButtonSize.small,
              child: SizedBox(
                width: maxWidth,
                child: elementExpanded
                    ? Center(
                        child: text,
                      )
                    : text,
              ),
              onPressed: () => options != null
                  ? SharedWidgets.showIosPickerDialog(
                      translations: translations,
                      context: context,
                      options: options!,
                      selected: selected,
                      showValue: showValue!,
                      isObject: false,
                      onApproved: () => onChanged(options!.keys
                          .toList()[selectedItem >= 0 ? selectedItem : 0]),
                      onSelectedItemChanged: (int index) {
                        selectedItem = index;
                      },
                    )
                  : null,
            );
    }

    return Globals.inMacosStyle()
        ? MacosPopupButton<String>(
            value: selected,
            onChanged: (String? value) {
              onChanged(value);
            },
            items: (options != null && options!.isNotEmpty)
                ? options!.keys.map<MacosPopupMenuItem<String>>((String key) {
                    return MacosPopupMenuItem<String>(
                      value: key,
                      child: SizedBox(
                        width: maxWidth,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical:
                                  optionsWithVerticalSpace == true ? 8.0 : 0.0),
                          child: Text(
                            showValue! ? options![key]! : key,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList()
                : [],
          )
        : SizedBox(
            width: maxWidth,
            child: DropdownButton<String>(
              value: selected,
              isExpanded: elementExpanded,
              hint: placeholder != null
                  ? Text(
                      placeholder!,
                      style: TextStyle(
                        color: ColorDefs.textColor(context: context),
                        fontSize: 12.0,
                      ),
                    )
                  : null,
              //dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: ColorDefs.iconColor(context: context),
              ),
              iconSize: 32,
              elevation: 16,
              style: TextStyle(
                color: ColorDefs.textColor(context: context),
              ),
              underline: Container(
                height: 0,
                color: Colors.blue,
              ),
              onChanged: (String? value) {
                onChanged(value);
              },
              items: (options != null && options!.isNotEmpty)
                  ? (options!.keys.map<DropdownMenuItem<String>>((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: SizedBox(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: optionsWithVerticalSpace == true
                                    ? 8.0
                                    : 0.0),
                            child: Text(
                              showValue! ? options![key]! : key,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      );
                    }).toList())
                  : [],
            ),
          );
  }

  Widget dropdown({
    required bool expanded,
    required bool elementExpanded,
    required BuildContext context,
  }) =>
      Container(
        width: expanded ? double.infinity : null,
        height: Globals.inIosStyle()
            ? 56.0
            : Globals.selectBoxInMacStyle()
                ? null
                : 36.0,
        padding: Globals.inMacosStyle()
            ? null
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: Globals.inMacosStyle()
            ? null
            : RoonmatrixStyles.boxDecoration(
                fillColor: ColorDefs.elementBackgroundColor(context: context),
              ),
        child: readOnly == true
            ? dropdownReadonlyElement(context: context)
            : dropdownElement(
                context: context,
                expanded: expanded,
                elementExpanded: elementExpanded),
      );

  @override
  Widget build(BuildContext context) {
    BuildContext dropdownContext = context;
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
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        label!,
                        style: TextStyle(
                          color: labelColor ??
                              ColorDefs.textColor(context: context),
                          fontSize: labelFontSize,
                          fontWeight: labelWeight,
                        ),
                      ),
                    ),
                  dropdown(
                      expanded: expanded!,
                      elementExpanded: elementExpanded!,
                      context: dropdownContext),
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
                        fontSize: labelFontSize,
                      ),
                    ),
                    const SizedBox(
                      height: 4.0,
                    ),
                  ],
                  dropdown(
                      expanded: expanded!,
                      elementExpanded: elementExpanded!,
                      context: dropdownContext),
                ],
              ),
      ),
    );
  }
}
