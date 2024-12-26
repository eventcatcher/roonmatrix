import 'dart:io';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class SearchField extends StatefulWidget {
  final bool showMacStyle;
  final TextEditingController controller;
  final String type;

  const SearchField({
    super.key,
    required this.showMacStyle,
    required this.controller,
    required this.type,
  });

  @override
  SearchFieldState createState() => SearchFieldState();
}

class SearchFieldState extends State<SearchField> {
  bool get showMacStyle => widget.showMacStyle;
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
                  color: SharedWidgets.elementBackgroundColor(
                      showMacStyle: showMacStyle, context: context),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: Platform.isIOS ||
                                  (showMacStyle == true && Platform.isMacOS)
                              ? 0.0
                              : 4.0,
                        ),
                        child: EditableSinglelineText(
                          showMacStyle: showMacStyle,
                          text: controller.text,
                          aligned: 'inline',
                          decoupled: false,
                          noDecoration: true,
                          prefixIcon: Icon(CupertinoIcons.search,
                              size: 18.0, color: Colors.black),
                          placeholder:
                              translations['searchfieldHint'] ?? 'search',
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
                    if (!Platform.isIOS && (!showMacStyle || !Platform.isMacOS))
                      IconButton(
                        icon: Icon(Icons.close,
                            color: SharedWidgets.iconColor(
                                showMacStyle: widget.showMacStyle,
                                context: context)),
                        padding: const EdgeInsets.all(4.0),
                        constraints: const BoxConstraints(),
                        splashRadius: 1,
                        onPressed: () {
                          setState(() {
                            controller.text = '';
                            mainBloc.setSearchFilter(type: type, filter: '');
                          });
                        },
                      )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
