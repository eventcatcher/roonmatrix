import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

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

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
          }

          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minWidth: 200.0, minHeight: 36.0),
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
                        padding: const EdgeInsets.only(
                            left: 4.0, bottom: 1.0, top: 9.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: translationsLoaded
                                ? translations['searchfieldHint'] ?? 'search'
                                : 'search',
                            counter: const Offstage(),
                            icon: const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(CupertinoIcons.search, size: 18.0),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.all(0),
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
                              mainBloc.setSearchFilter(
                                  type: type, filter: value);
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
                          mainBloc.setSearchFilter(type: type, filter: '');
                        });
                      },
                      color: Colors.black45,
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
