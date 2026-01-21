import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/helper/roonmatrix_styles.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SelectBox extends StatefulWidget {
  final Map<String, dynamic> translations;
  final Map<String, String>? options;
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final String? selected;
  final bool? showValue;
  final bool? inRow;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final bool? readOnlyColoredGrey;
  final bool? optionsWithVerticalSpace;
  final void Function(String? value) onChanged;

  const SelectBox({
    super.key,
    required this.translations,
    required this.options,
    this.aligned,
    this.label,
    this.labelColor,
    this.placeholder,
    this.selected,
    this.showValue = false,
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
  Map<String, dynamic> get translations => widget.translations;
  Map<String, String>? get options => widget.options;
  String? get aligned => widget.aligned;
  String? get label => widget.label;
  Color? get labelColor => widget.labelColor;
  String? get placeholder => widget.placeholder;
  String? get selected => widget.selected;
  bool? get showValue => widget.showValue;
  bool? get inRow => widget.inRow;
  bool? get noVerticalSpace => widget.noVerticalSpace;
  bool? get readOnly => widget.readOnly;
  bool? get readOnlyColoredGrey => widget.readOnlyColoredGrey;
  bool? get optionsWithVerticalSpace => widget.optionsWithVerticalSpace;
  void Function(String? value) get onChanged => widget.onChanged;

  final double labelFontSize = 12.0;

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
              : SharedWidgets.textColor(context: context),
          fontSize: 13.0,
        ),
      ),
    );
  }

  Widget dropdownElement({
    required BuildContext context,
    required bool expanded,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return options!.keys.toList().isEmpty
          ? Text(translations['zonePickerOptionsEmpty'] ?? 'none')
          : CupertinoButton(
              child: Text(
                selected != null
                    ? showValue!
                        ? options![selected]
                        : selected!
                    : translations['zonePickerSelectionEmpty'] ??
                        'Please Select',
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

    return SharedWidgets.inMacosStyle()
        ? MacosPopupButton<String>(
            value: selected,
            onChanged: (String? value) {
              onChanged(value);
            },
            items: (options != null && options!.isNotEmpty)
                ? options!.keys.map<MacosPopupMenuItem<String>>((String key) {
                    return MacosPopupMenuItem<String>(
                      value: key,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                optionsWithVerticalSpace == true ? 8.0 : 0.0),
                        child: Text(
                          showValue! ? options![key]! : key,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    );
                  }).toList()
                : [],
          )
        : DropdownButton<String>(
            value: selected,
            isExpanded: expanded,
            hint: placeholder != null
                ? Text(
                    placeholder!,
                    style: TextStyle(
                      color: SharedWidgets.textColor(context: context),
                      fontSize: 12.0,
                    ),
                  )
                : null,
            //dropdownColor: Colors.white,
            icon: Icon(
              Icons.arrow_drop_down,
              color: SharedWidgets.iconColor(context: context),
            ),
            iconSize: 32,
            elevation: 16,
            style: TextStyle(
              color: SharedWidgets.textColor(context: context),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                optionsWithVerticalSpace == true ? 8.0 : 0.0),
                        child: Text(
                          showValue! ? options![key]! : key,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    );
                  }).toList())
                : [],
          );
  }

  Widget dropdown({
    required bool expanded,
    required BuildContext context,
  }) =>
      Container(
        height: SharedWidgets.inIosStyle()
            ? 56.0
            : SharedWidgets.selectBoxInMacStyle()
                ? null
                : 36.0,
        padding: SharedWidgets.inMacosStyle()
            ? null
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: SharedWidgets.inMacosStyle()
            ? null
            : RoonmatrixStyles.boxDecoration(
                fillColor:
                    SharedWidgets.elementBackgroundColor(context: context),
              ),
        child: readOnly == true
            ? dropdownReadonlyElement(context: context)
            : dropdownElement(context: context, expanded: expanded),
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
                    Text(
                      label!,
                      style: TextStyle(
                        color: SharedWidgets.textColor(context: context),
                        fontSize: labelFontSize,
                      ),
                    ),
                  dropdown(expanded: false, context: dropdownContext),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(
                      label!,
                      style: TextStyle(
                        color: labelColor ??
                            SharedWidgets.textColor(context: context),
                        fontSize: labelFontSize,
                      ),
                    ),
                    const SizedBox(
                      height: 4.0,
                    ),
                  ],
                  dropdown(expanded: true, context: dropdownContext),
                ],
              ),
      ),
    );
  }
}
