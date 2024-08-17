import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String type;

  const SearchField({
    super.key,
    required this.controller,
    required this.type,
  });

  @override
  SearchFieldState createState() => SearchFieldState();
}

class SearchFieldState extends State<SearchField> {
  TextEditingController get controller => widget.controller;
  String get type => widget.type;

  late OptionsBloc optionsBloc;

  @override
  void initState() {
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200.0),
        child: Container(
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
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 4.0, bottom: 1.0, top: 9.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'search',
                      counter: Offstage(),
                      icon: Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(CupertinoIcons.search, size: 18.0),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.all(0),
                    ),
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 19.0,
                        decorationStyle: TextDecorationStyle.double),
                    enableSuggestions: false,
                    controller: controller,
                    onChanged: (String value) {
                      EasyDebounce.debounce('searchfield-debouncer',
                          const Duration(milliseconds: 500), () {
                        optionsBloc.setSearchFilter(type: type, filter: value);
                      });
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                padding: const EdgeInsets.all(4.0),
                constraints: const BoxConstraints(),
                splashRadius: 1,
                onPressed: () {
                  setState(() {
                    controller.text = '';
                    optionsBloc.setSearchFilter(type: type, filter: '');
                  });
                },
                color: Colors.black45,
              )
            ],
          ),
        ),
      ),
    );
  }
}
