import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/ui/helper/roonmatrix_styles.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/text_field_element.dart';

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
    this.errorMessageHandler,
  });

  @override
  EditableSinglelineTextState createState() => EditableSinglelineTextState();
}

class EditableSinglelineTextState extends State<EditableSinglelineText> {
  Map<String, dynamic> get translations => widget.translations;
  TextInputType get inputType => widget.inputType;
  List<TextInputFormatter>? get formatters => widget.formatters;
  String? get aligned => widget.aligned;
  String? get label => widget.label;
  Color? get labelColor => widget.labelColor;
  String? get placeholder => widget.placeholder;
  String get text => widget.text;
  TextEditingController? get controller => widget.controller;
  dynamic get prefixIcon => widget.prefixIcon;
  dynamic get suffixIcon => widget.suffixIcon;
  int? get maxLength => widget.maxLength;
  bool get readOnly => widget.readOnly;
  bool get noCounter => widget.noCounter;
  bool get decoupled => widget.decoupled;
  bool get debounce => widget.debounce;
  bool get noDecoration => widget.noDecoration;
  bool get filled => widget.filled;
  Color? get fillColorForValidationError => widget.fillColorForValidationError;
  String Function(String text)? get filter => widget.filter;
  void Function(String text)? get onChanged => widget.onChanged;
  void Function(Function func)? get getTextCallback => widget.getTextCallback;
  bool Function(String text)? get validation => widget.validation;
  String Function(String text)? get errorMessageHandler =>
      widget.errorMessageHandler;

  final TextEditingController _userTextController = TextEditingController();
  final Color readOnlyColor = Colors.grey.shade500;
  final int debounceTime = 800; // textfield debounce time in milliseconds

  bool valid = true;
  bool withCents =
      false; // value has dot with 2 cent columns (or more which we need to cut)
  String? errorMessage = '';

  late MainRepository mainRepository;
  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);

    switch (aligned) {
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
    if (inputType == const TextInputType.numberWithOptions(decimal: true)) {
      withCents = true;
    }
    _userTextController.text = text;

    if (getTextCallback != null) {
      getTextCallback!(getText);
    }

    super.initState();
  }

  @override
  void didUpdateWidget(EditableSinglelineText oldWidget) {
    if (decoupled == false && _userTextController.text != text) {
      _userTextController.text = widget.text;
      _userTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: _userTextController.text.length));
    }

    if (validation != null) {
      valid = validation!(_userTextController.text);
    }
    if (errorMessageHandler != null) {
      errorMessage = errorMessageHandler!(_userTextController.text);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _userTextController.dispose();
    super.dispose();
  }

  String getText() => _userTextController.text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              overflow: TextOverflow
                  .ellipsis, // fade is maybe the better alternative, because you see more of the text
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: SharedWidgets.brightness() == Brightness.dark
                    ? SharedWidgets.textColor(context: context)
                    : labelColor ?? SharedWidgets.textColor(context: context),
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
              decoration: noDecoration == true
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
                      borderRadius: SharedWidgets.borderRadius(),
                    ),
              padding: EdgeInsets.only(
                  top: maxLength != null && placeholder == null
                      ? noCounter
                          ? 4.0
                          : 12.0
                      : 0.0),
              child: TextFieldElement(
                readOnly: readOnly,
                placeholder: placeholder ??
                    translations['pleaseTypeSettingPlaceholder'] ??
                    'Please enter here',
                maxLength: maxLength,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                buildCounter: maxLength != null
                    ? (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        return Container(
                          transform: Matrix4.translationValues(0, -42, 0),
                          child: Text(
                            noCounter ? "" : "$currentLength/$maxLength",
                            style: const TextStyle(fontSize: 10.0),
                          ),
                        );
                      }
                    : null,
                keyboardType: inputType,
                inputFormatters: formatters,
                decoration: RoonmatrixStyles.inputDecoration(
                  placeholder: placeholder ??
                      translations['pleaseTypeSettingPlaceholder'] ??
                      'Please enter here',
                  prefixIcon: prefixIcon,
                  suffixIcon: suffixIcon ??
                      InkWell(
                        onTap: () {
                          _userTextController.clear();
                          if (onChanged != null) {
                            onChanged!('');
                          }
                        },
                        child: Icon(
                          Icons.clear,
                          size: 24,
                        ),
                      ),
                  noCounter: noCounter,
                  fillColor: (fillColorForValidationError != null && !valid)
                      ? fillColorForValidationError
                      : SharedWidgets.brightness() == Brightness.dark
                          ? SharedWidgets.elementBackgroundColorLighter(
                              context: context)
                          : Colors.white,
                  borderColor: Colors.transparent,
                  filled: filled,
                ),
                style: TextStyle(
                  color: readOnly
                      ? readOnlyColor
                      : SharedWidgets.textColor(context: context),
                  fontSize: 16.0,
                ),
                controller: _userTextController,
                onChanged: (String value) {
                  bool doTextCorrection = false;
                  if (filter != null) {
                    String unfilteredValue = value;
                    value = filter!(value);
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
                  if (mounted && validation != null) {
                    setState(() {
                      valid = validation!(value);
                      if (errorMessageHandler != null) {
                        errorMessage = errorMessageHandler!(value);
                      }
                    });
                  }

                  if (controller != null) {
                    controller!.text = value;
                  }

                  if (onChanged != null) {
                    if (debounce == true) {
                      EasyDebounce.debounce(
                          mainRepository.getDebounceTag(label: label),
                          Duration(milliseconds: debounceTime),
                          () => onChanged!(value));
                    } else {
                      onChanged!(value);
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
}
