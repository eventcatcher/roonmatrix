import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';

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
  Map<String, dynamic> get translations => widget.translations;
  String? get label => widget.label;
  int get maxLines => widget.maxLines;
  double? get height => widget.height;
  String get text => widget.text;
  String? get placeholder => widget.placeholder;
  TextEditingController? get textController => widget.textController;
  void Function(String value)? get onChanged => widget.onChanged;
  String Function(String text)? get filter => widget.filter;
  void Function(Function func)? get getTextCallback => widget.getTextCallback;
  bool Function(String text)? get validation => widget.validation;
  String Function(String text)? get errorMessageHandler =>
      widget.errorMessageHandler;

  final TextEditingController _userTextController = TextEditingController();
  final int debounceTime = 2500; // textfield debounce time in milliseconds

  bool valid = true;
  String? errorMessage = '';

  @override
  void initState() {
    TextEditingController c = textController ?? _userTextController;

    c.text = text;

    if (getTextCallback != null) {
      getTextCallback!(getText);
    }

    super.initState();
  }

  @override
  void didUpdateWidget(EditableMultilineText oldWidget) {
    TextEditingController c = textController ?? _userTextController;

    if (validation != null) {
      valid = validation!(c.text);
    }
    if (errorMessageHandler != null) {
      errorMessage = errorMessageHandler!(c.text);
    }

    super.didUpdateWidget(oldWidget);
  }

  String getText() {
    TextEditingController c = textController ?? _userTextController;

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
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                label!,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: ColorDefs.textColor(context: context),
                  fontSize: 12.0,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: height,
                  decoration: Globals.inIosStyle() || Globals.inMacosStyle()
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
                          color: ColorDefs.elementBackgroundColor(
                              context: context),
                          borderRadius: Globals.borderRadius(),
                        ),
                  child: Globals.inIosStyle() || Globals.inMacosStyle()
                      ? CupertinoTextField(
                          controller: textController ?? _userTextController,
                          placeholder: placeholder ??
                              translations['pleaseTypeMessagePlaceholder'] ??
                              'Please write message here',
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ColorDefs.borderColor(context: context),
                            ),
                            borderRadius: Globals.borderRadius(),
                          ),
                          style: TextStyle(
                            color: ColorDefs.textColor(context: context),
                            fontSize: 16.0,
                          ),
                          maxLines: maxLines,
                          maxLength: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (String value) {
                            bool doTextCorrection = false;

                            if (filter != null) {
                              String unfilteredValue = value;
                              value = filter!(value);
                              if (unfilteredValue != value) {
                                doTextCorrection = true;
                              }
                            }

                            if (doTextCorrection == true) {
                              TextEditingController c =
                                  textController ?? _userTextController;
                              c.text = value;
                              c.selection = TextSelection.fromPosition(
                                  TextPosition(offset: c.text.length));
                            }

                            if (mounted && validation != null) {
                              setState(() {
                                valid = validation!(value);
                                if (errorMessageHandler != null) {
                                  errorMessage = errorMessageHandler!(value);
                                }
                              });
                            }

                            if (onChanged != null) {
                              return EasyDebounce.debounce(
                                  '$label-debouncer',
                                  Duration(milliseconds: debounceTime),
                                  () => onChanged!(value));
                            }
                          })
                      : TextField(
                          controller: textController ?? _userTextController,
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color: ColorDefs.textColor(context: context),
                            fontSize: 14.0,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                translations['pleaseTypeMessagePlaceholder'] ??
                                    'Please write message here',
                            border: InputBorder.none, // removes blue focus line
                            contentPadding: EdgeInsets.all(9.0),
                          ),
                          maxLines: maxLines,
                          maxLength: null,
                          keyboardType: TextInputType.multiline,
                          onChanged: (String value) {
                            bool doTextCorrection = false;

                            if (filter != null) {
                              String unfilteredValue = value;
                              value = filter!(value);
                              if (unfilteredValue != value) {
                                doTextCorrection = true;
                              }
                            }

                            if (doTextCorrection == true) {
                              TextEditingController c =
                                  textController ?? _userTextController;
                              c.text = value;
                              c.selection = TextSelection.fromPosition(
                                  TextPosition(offset: c.text.length));
                            }

                            if (onChanged != null) {
                              EasyDebounce.debounce(
                                  '$label-debouncer',
                                  Duration(milliseconds: debounceTime),
                                  () => onChanged!(value));
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
                  color: Globals.brightness() == Brightness.dark
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
