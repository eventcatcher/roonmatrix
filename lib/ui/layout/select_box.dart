import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/roonmatrix_styles.dart';
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
  BuildContext? modalContext;
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

  void _showDialog({required BuildContext context, required Widget child}) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        modalContext = context;
        return Container(
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
        );
      },
    );
  }

  Widget dropdownElement(
      {required bool expanded, required BuildContext context}) {
    if (SharedWidgets.inIosStyle()) {
      return widget.options!.keys.toList().isEmpty
          ? Text(widget.translations['zonePickerOptionsEmpty'] ?? 'none')
          : CupertinoButton(
              child: Text(
                widget.selected != null
                    ? widget.showValue!
                        ? widget.options![widget.selected]
                        : widget.selected!
                    : widget.translations['zonePickerSelectionEmpty'] ??
                        'Please Select',
              ),
              onPressed: () => _showDialog(
                context: context,
                child: Column(
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
                            Navigator.pop(modalContext ?? context);
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
                            Navigator.pop(modalContext ?? context);
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
                              widget.showValue!
                                  ? widget.options!.values.toList()[index]
                                  : widget.options!.keys.toList()[index],
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

    return SharedWidgets.inMacosStyle()
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
                          widget.showValue! ? widget.options![key]! : key,
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
                          widget.showValue! ? widget.options![key]! : key,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    );
                  }).toList())
                : [],
          );
  }

  Widget dropdownReadonlyElement({required BuildContext context}) {
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
              : SharedWidgets.textColor(context: context),
          fontSize: 13.0,
        ),
      ),
    );
  }

  Widget dropdown({required bool expanded, required BuildContext context}) =>
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
        child: widget.readOnly == true
            ? dropdownReadonlyElement(context: context)
            : dropdownElement(expanded: expanded, context: context),
      );

  @override
  Widget build(BuildContext context) {
    BuildContext dropdownContext = context;
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
                        color: SharedWidgets.textColor(context: context),
                        fontSize: 12.0,
                      ),
                    ),
                  dropdown(expanded: false, context: dropdownContext),
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
                            SharedWidgets.textColor(context: context),
                        fontSize: 12.0,
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

  @override
  void dispose() {
    super.dispose();
  }
}
