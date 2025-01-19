import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class EditableMultilineText extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String? label;
  final int maxLines;
  final double? height;
  final TextEditingController textController;
  final void Function(String value)? onChanged;

  const EditableMultilineText({
    super.key,
    required this.translations,
    this.label,
    this.maxLines = 5,
    this.height,
    required this.textController,
    this.onChanged,
  });

  @override
  EditableMultilineTextState createState() => EditableMultilineTextState();
}

class EditableMultilineTextState extends State<EditableMultilineText> {
  late EdgeInsetsGeometry margin;
  int debounceTime = 2500; // textfield debounce time in milliseconds

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 0.0, top: 0.0),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                widget.label!,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: SharedWidgets.textColor(context: context),
                  fontSize: 12.0,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: widget.height,
                  decoration:
                      SharedWidgets.inIosStyle() || SharedWidgets.inMacosStyle()
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
                                  context: context),
                              borderRadius: BorderRadius.all(Radius.circular(
                                  SharedWidgets.inIosStyle() ? 8 : 5))),
                  child: SharedWidgets.inIosStyle() ||
                          SharedWidgets.inMacosStyle()
                      ? CupertinoTextField(
                          controller: widget.textController,
                          placeholder: widget.translations[
                                  'pleaseTypeMessagePlaceholder'] ??
                              'Please write message here',
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  SharedWidgets.borderColor(context: context),
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(
                                SharedWidgets.inIosStyle() ? 8 : 5)),
                          ),
                          style: TextStyle(
                            color: SharedWidgets.textColor(context: context),
                            fontSize: 16.0,
                          ),
                          maxLines: widget.maxLines,
                          maxLength: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (String value) => widget.onChanged != null
                              ? EasyDebounce.debounce(
                                  '${widget.label}-debouncer',
                                  Duration(milliseconds: debounceTime),
                                  () => widget.onChanged!(value))
                              : null,
                        )
                      : TextField(
                          controller: widget.textController,
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color: SharedWidgets.textColor(context: context),
                            fontSize: 14.0,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.translations[
                                    'pleaseTypeMessagePlaceholder'] ??
                                'Please write message here',
                            contentPadding: EdgeInsets.all(9.0),
                          ),
                          maxLines: widget.maxLines,
                          maxLength: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (String value) => widget.onChanged != null
                              ? EasyDebounce.debounce(
                                  '${widget.label}-debouncer',
                                  Duration(milliseconds: debounceTime),
                                  () => widget.onChanged!(value))
                              : null,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
