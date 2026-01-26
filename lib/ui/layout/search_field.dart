import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
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

  final double minWidth = 200.0;
  final double minHeight = 36.0;
  final Duration debounceDuration = Duration(milliseconds: 500);
  final BoxShadow boxShadow = BoxShadow(
    color: Colors.grey,
    offset: Offset(0.1, 0.5),
    blurRadius: 0.1,
    blurStyle: BlurStyle.normal,
  );

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
                  BoxConstraints(minWidth: minWidth, minHeight: minHeight),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [boxShadow],
                  color: ColorDefs.textFieldBackgroundColor(context: context),
                  borderRadius: Globals.borderRadius(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: Globals.inIosStyle() || Globals.inMacosStyle()
                              ? 0.0
                              : 4.0,
                        ),
                        child: EditableSinglelineText(
                          translations: translations,
                          text: controller.text,
                          aligned: 'inline',
                          filled: Globals.inIosStyle() || Globals.inMacosStyle()
                              ? true
                              : false,
                          decoupled: false,
                          noDecoration: true,
                          prefixIcon: Icon(CupertinoIcons.search,
                              size: 18.0,
                              color: ColorDefs.iconColor(context: context)),
                          placeholder:
                              translations['searchfieldHint'] ?? 'search',
                          controller: controller,
                          onChanged: (String value) {
                            value = value.escapeAllSpecialChars();
                            if (value == '') {
                              mainBloc.setSearchFilter(type: type, filter: '');
                              setState(() => controller.text = '');
                            } else {
                              EasyDebounce.debounce(
                                'searchfield-debouncer',
                                debounceDuration,
                                () {
                                  if (controller.text.isNotEmpty) {
                                    mainBloc.setSearchFilter(
                                        type: type, filter: value);
                                  }
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
