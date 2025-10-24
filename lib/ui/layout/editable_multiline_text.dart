import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class EditableMultilineText extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String? label;
  final int maxLines;
  final double? height;
  final String text;
  final String? placeholder;
  final TextEditingController? textController;
  final void Function(String value)? onChanged;
  final String Function(String text)? filter;
  final void Function(Function func)? getTextCallback;
  final bool Function(String text)? validation;
  final String Function(String text)? errorMessageHandler;

  const EditableMultilineText({
    super.key,
    required this.translations,
    this.label,
    this.maxLines = 5,
    this.height,
    this.text = '',
    this.placeholder,
    this.textController,
    this.onChanged,
    this.filter,
    this.getTextCallback,
    this.validation,
    this.errorMessageHandler,
  });

  @override
  EditableMultilineTextState createState() => EditableMultilineTextState();
}

class EditableMultilineTextState extends State<EditableMultilineText> {
  final TextEditingController _userTextController = TextEditingController();
  late EdgeInsetsGeometry margin;
  int debounceTime = 2500; // textfield debounce time in milliseconds
  bool valid = true;
  String? errorMessage = '';

  @override
  void initState() {
    TextEditingController c = widget.textController ?? _userTextController;

    c.text = widget.text;

    if (widget.getTextCallback != null) {
      widget.getTextCallback!(getText);
    }

    super.initState();
  }

  @override
  void didUpdateWidget(EditableMultilineText oldWidget) {
    TextEditingController c = widget.textController ?? _userTextController;

    if (widget.validation != null) {
      valid = widget.validation!(c.text);
    }
    if (widget.errorMessageHandler != null) {
      errorMessage = widget.errorMessageHandler!(c.text);
    }

    super.didUpdateWidget(oldWidget);
  }

  String getText() {
    TextEditingController c = widget.textController ?? _userTextController;

    return c.text;
  }

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
                          controller:
                              widget.textController ?? _userTextController,
                          placeholder: widget.placeholder ??
                              widget.translations[
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
                          onChanged: (String value) {
                            bool doTextCorrection = false;

                            if (widget.filter != null) {
                              String unfilteredValue = value;
                              value = widget.filter!(value);
                              if (unfilteredValue != value) {
                                doTextCorrection = true;
                              }
                            }

                            if (doTextCorrection == true) {
                              TextEditingController c =
                                  widget.textController ?? _userTextController;
                              c.text = value;
                              c.selection = TextSelection.fromPosition(
                                  TextPosition(offset: c.text.length));
                            }

                            if (mounted && widget.validation != null) {
                              setState(() {
                                valid = widget.validation!(value);
                                if (widget.errorMessageHandler != null) {
                                  errorMessage =
                                      widget.errorMessageHandler!(value);
                                }
                              });
                            }

                            if (widget.onChanged != null) {
                              return EasyDebounce.debounce(
                                  '${widget.label}-debouncer',
                                  Duration(milliseconds: debounceTime),
                                  () => widget.onChanged!(value));
                            }
                          })
                      : TextField(
                          controller:
                              widget.textController ?? _userTextController,
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
                          onChanged: (String value) {
                            bool doTextCorrection = false;

                            if (widget.filter != null) {
                              String unfilteredValue = value;
                              value = widget.filter!(value);
                              if (unfilteredValue != value) {
                                doTextCorrection = true;
                              }
                            }

                            if (doTextCorrection == true) {
                              TextEditingController c =
                                  widget.textController ?? _userTextController;
                              c.text = value;
                              c.selection = TextSelection.fromPosition(
                                  TextPosition(offset: c.text.length));
                            }

                            if (widget.onChanged != null) {
                              EasyDebounce.debounce(
                                  '${widget.label}-debouncer',
                                  Duration(milliseconds: debounceTime),
                                  () => widget.onChanged!(value));
                            }
                          },
                        ),
                ),
              ),
            ],
          ),
          if (errorMessage != null &&
              errorMessage!.isNotEmpty &&
              valid == false)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                errorMessage!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: SharedWidgets.brightness() == Brightness.dark
                      ? Colors.red.shade200
                      : Colors.red,
                  fontSize: 10.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
