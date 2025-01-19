import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roonmatrix/ui/layout/roonmatrix_styles.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/text_field_element.dart';
import 'package:uuid/uuid.dart';

class EditableSinglelineText extends StatefulWidget {
  final Map<String, dynamic> translations;
  final TextInputType inputType;
  final List<TextInputFormatter>? formatters;
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final String text;
  final TextEditingController? controller;
  final dynamic prefixIcon;
  final dynamic suffixIcon;
  final int? maxLength;
  final bool readOnly;
  final bool noCounter;
  final bool decoupled;
  final bool debounce;
  final bool noDecoration;
  final bool filled;
  final Color? fillColorForValidationError;
  final String Function(String text)? filter;
  final void Function(String text)? onChanged;
  final void Function(Function func)? getTextCallback;
  final bool Function(String text)? validation;
  final String Function(String text)? errorMessageHandler;

  const EditableSinglelineText({
    super.key,
    required this.translations,
    this.inputType = TextInputType.text,
    this.formatters,
    this.aligned,
    this.label,
    this.labelColor = Colors.black,
    this.placeholder,
    required this.text,
    this.controller,
    this.errorMessageHandler,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.readOnly = false,
    this.noCounter = false,
    this.decoupled = true,
    this.debounce = true,
    this.noDecoration = false,
    this.filled = true,
    this.fillColorForValidationError,
    this.filter,
    this.onChanged,
    this.getTextCallback,
    this.validation,
  });

  @override
  EditableSinglelineTextState createState() => EditableSinglelineTextState();
}

class EditableSinglelineTextState extends State<EditableSinglelineText> {
  final TextEditingController _userTextController = TextEditingController();
  late EdgeInsetsGeometry margin;
  Color readOnlyColor = Colors.grey.shade500;
  int debounceTime = 800; // textfield debounce time in milliseconds
  bool valid = true;
  bool withCents =
      false; // value has dot with 2 cent columns (or more which we need to cut)
  String? errorMessage = '';

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
      case "horizontal":
        margin = const EdgeInsets.only(left: 16.0, right: 16.0);
        break;
      case "inline":
        margin = const EdgeInsets.all(0);
        break;
      default:
        margin = const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 6.0, bottom: 6.0);
    }
    if (widget.inputType ==
        const TextInputType.numberWithOptions(decimal: true)) {
      withCents = true;
    }
    _userTextController.text = widget.text;

    if (widget.getTextCallback != null) {
      widget.getTextCallback!(getText);
    }

    if (widget.validation != null) {
      valid = widget.validation!(widget.text);
    }
    if (widget.errorMessageHandler != null) {
      errorMessage = widget.errorMessageHandler!(widget.text);
    }

    super.initState();
  }

  @override
  void didUpdateWidget(EditableSinglelineText oldWidget) {
    if (widget.decoupled == false && _userTextController.text != widget.text) {
      _userTextController.text = widget
          .text; // fix: delete a dokument -> results in update with another text
      _userTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: _userTextController.text.length));
    }

    super.didUpdateWidget(oldWidget);
  }

  String getDebounceTag() {
    String tag = "";

    if (widget.label != null) {
      tag = widget.label!.replaceAll(" ", "-");
    } else {
      Uuid uuid = const Uuid();
      tag = uuid.v4();
    }

    return tag;
  }

  String getText() {
    return _userTextController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              overflow: TextOverflow
                  .ellipsis, // fade is maybe the better alternative, because you see more of the text
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: SharedWidgets.brightness() == Brightness.dark
                    ? SharedWidgets.textColor(context: context)
                    : widget.labelColor ??
                        SharedWidgets.textColor(context: context),
                fontSize: 12.0,
              ),
            ),
            const SizedBox(
              height: 4.0,
            ),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(height: 36),
            child: Container(
              decoration: widget.noDecoration == true
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
                      color: SharedWidgets.textFieldBackgroundColor(
                          context: context),
                      borderRadius: BorderRadius.all(
                          Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5))),
              padding: EdgeInsets.only(
                  top: widget.maxLength != null && widget.placeholder == null
                      ? widget.noCounter
                          ? 4.0
                          : 12.0
                      : 0.0),
              child: TextFieldElement(
                readOnly: widget.readOnly,
                placeholder: widget.placeholder ??
                    widget.translations['pleaseTypeSettingPlaceholder'] ??
                    'Please write message here',
                maxLength: widget.maxLength,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                buildCounter: widget.maxLength != null
                    ? (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) {
                        return Container(
                          transform: Matrix4.translationValues(0, -42, 0),
                          child: Text(
                            widget.noCounter ? "" : "$currentLength/$maxLength",
                            style: const TextStyle(fontSize: 10.0),
                          ),
                        );
                      }
                    : null,
                keyboardType: widget.inputType,
                inputFormatters: widget.formatters,
                decoration: RoonmatrixStyles.inputDecoration(
                  placeholder: widget.placeholder ??
                      widget.translations['pleaseTypeSettingPlaceholder'] ??
                      'Please write message here',
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon ??
                      InkWell(
                        onTap: () {
                          _userTextController.clear();
                          if (widget.onChanged != null) {
                            widget.onChanged!('');
                          }
                        },
                        child: Icon(
                          Icons.clear,
                          size: 24,
                        ),
                      ),
                  noCounter: widget.noCounter,
                  fillColor:
                      (widget.fillColorForValidationError != null && !valid)
                          ? widget.fillColorForValidationError
                          : SharedWidgets.brightness() == Brightness.dark
                              ? SharedWidgets.elementBackgroundColorLighter(
                                  context: context)
                              : Colors.white,
                  borderColor: Colors.transparent,
                  filled: widget.filled,
                ),
                style: TextStyle(
                  color: widget.readOnly
                      ? readOnlyColor
                      : SharedWidgets.textColor(context: context),
                  fontSize: 16.0,
                ),
                controller: _userTextController,
                onChanged: (String value) {
                  bool doTextCorrection = false;
                  if (widget.filter != null) {
                    String unfilteredValue = value;
                    value = widget.filter!(value);
                    if (unfilteredValue != value) {
                      doTextCorrection = true;
                    }
                  }
                  if (withCents == true) {
                    int dot = value.indexOf('.');
                    int comma = value.indexOf(',');
                    if (dot >= 0) {
                      value = value.replaceAll(
                          '.', ','); // convert dot to comma (for samsung)
                    }
                    int centPart = comma >= 0 ? value.length - comma - 1 : 0;
                    if (centPart > 2) {
                      value = value.substring(0, comma + 3);
                    }
                    if (dot >= 0 || centPart > 2) {
                      doTextCorrection = true;
                    }
                  }
                  if (doTextCorrection == true) {
                    _userTextController.text = value;
                    _userTextController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _userTextController.text.length));
                  }
                  if (mounted && widget.validation != null) {
                    setState(() {
                      valid = widget.validation!(value);
                      if (widget.errorMessageHandler != null) {
                        errorMessage = widget.errorMessageHandler!(value);
                      }
                    });
                  }

                  if (widget.controller != null) {
                    widget.controller!.text = value;
                  }

                  if (widget.onChanged != null) {
                    if (widget.debounce == true) {
                      EasyDebounce.debounce(
                          getDebounceTag(),
                          Duration(milliseconds: debounceTime),
                          () => widget.onChanged!(value));
                    } else {
                      widget.onChanged!(value);
                    }
                  }
                },
              ),
            ),
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

  @override
  void dispose() {
    _userTextController.dispose();
    super.dispose();
  }
}
