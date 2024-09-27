import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

class EditableMultilineText extends StatefulWidget {
  final String? label;
  final TextEditingController textController;
  final void Function(String value)? onChanged;

  const EditableMultilineText({
    super.key,
    this.label,
    required this.textController,
    this.onChanged,
  });

  @override
  EditableMultilineTextState createState() => EditableMultilineTextState();
}

class EditableMultilineTextState extends State<EditableMultilineText> {
  late EdgeInsetsGeometry margin;
  int debounceTime = 1500; // textfield debounce time in milliseconds

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
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.0,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0.1, 0.5),
                          blurRadius: 0.1,
                          blurStyle: BlurStyle.normal,
                        )
                      ],
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.all(Radius.circular(4))),
                  child: TextFormField(
                    controller: widget.textController,
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12.0,
                    ),
                    // decoration: RoonmatrixStyles.inputDecoration(
                    //   borderColor: Colors.transparent,
                    // ),
                    maxLines: 5,
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
