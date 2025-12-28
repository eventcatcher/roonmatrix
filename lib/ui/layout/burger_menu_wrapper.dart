import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/burger_menu.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class BurgerMenuWrapper extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController animationController;
  final double? navigationTop;
  final bool isDrawerOpen;

  const BurgerMenuWrapper({
    super.key,
    required this.scaffoldKey,
    required this.animationController,
    this.navigationTop,
    required this.isDrawerOpen,
  });

  @override
  State<BurgerMenuWrapper> createState() => _BurgerMenuWrapperState();
}

class _BurgerMenuWrapperState extends State<BurgerMenuWrapper> {
  Map<String, dynamic> translations = {};
  String aboutAppMessage = '';
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late bool isDrawerOpen;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    isDrawerOpen = widget.isDrawerOpen;

    super.initState();
  }

  @override
  void didUpdateWidget(BurgerMenuWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    isDrawerOpen = widget.isDrawerOpen;
  }

  openBurgerMenuItem(String? key) {
    if (key == 'about') {
      SharedWidgets.openAboutModal(
          context: context,
          aboutAppMessage: aboutAppMessage,
          translations: translations);
    }
    if (key == 'settings') {
      SharedWidgets.openSettingsPage(context);
    }
  }

  Widget burgerMenuRaw(bool noPop) => BurgerMenu(
        translations: translations,
        noPop: noPop,
        navigationTop: widget.navigationTop,
        onClose: (String? key) {
          setState(() {
            isDrawerOpen = false;
            widget.animationController.reverse();
          });
          return openBurgerMenuItem(key);
        },
      );

  @override
  Widget build(BuildContext context) => BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          aboutAppMessage = translationsState.aboutAppMessage;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return const SizedBox();
        }

        return SharedWidgets.inIosStyle()
            ? burgerMenuRaw(true)
            : Drawer(
                child: Stack(
                  children: [
                    burgerMenuRaw(false),
                    Positioned(
                      top: (widget.navigationTop ?? 84.0) - 40,
                      left: 16.0,
                      child: InkWell(
                        onTap: () => setState(() {
                          isDrawerOpen = false;
                          widget.scaffoldKey.currentState?.openEndDrawer();
                        }),
                        child: Icon(
                          CupertinoIcons.clear,
                          color: Colors.white,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
      });
}
