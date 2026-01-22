import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/globals.dart';
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
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final Function({required bool visibility}) setDrawerVisibility;

  const BurgerMenuWrapper({
    super.key,
    required this.scaffoldKey,
    required this.animationController,
    this.navigationTop,
    required this.isDrawerOpen,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.setDrawerVisibility,
  });

  @override
  State<BurgerMenuWrapper> createState() => _BurgerMenuWrapperState();
}

class _BurgerMenuWrapperState extends State<BurgerMenuWrapper> {
  GlobalKey<ScaffoldState> get scaffoldKey => widget.scaffoldKey;
  AnimationController get animationController => widget.animationController;
  double? get navigationTop => widget.navigationTop;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  Function({required bool visibility}) get setDrawerVisibility =>
      widget.setDrawerVisibility;

  final double navigationTopFallback = 84.0;
  final double navigationTopOffset = -40.0;
  final double navigationLeftOffset = 16.0;

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

  void openBurgerMenuItem({
    required String? key,
    required BuildContext context,
  }) {
    if (key == 'about') {
      SharedWidgets.openAboutModal(
          context: context,
          aboutAppMessage: aboutAppMessage,
          translations: translations);
    }
    if (key == 'settings') {
      SharedWidgets.openSettingsPage(
        context: context,
        minDesktopSize: minDesktopSize,
        standardDesktopSize: standardDesktopSize,
      );
    }
  }

  Widget burgerMenuRaw({
    required bool noPop,
    required BuildContext context,
  }) =>
      BurgerMenu(
        translations: translations,
        noPop: noPop,
        navigationTop: navigationTop,
        onClose: (String? key) {
          setState(() {
            isDrawerOpen = false;
            setDrawerVisibility(visibility: isDrawerOpen);
            animationController.reverse();
          });
          return openBurgerMenuItem(key: key, context: context);
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

        return Globals.inIosStyle()
            ? burgerMenuRaw(
                noPop: true, context: scaffoldKey.currentContext ?? context)
            : Drawer(
                child: Stack(
                  children: [
                    burgerMenuRaw(
                        noPop: false,
                        context: scaffoldKey.currentContext ?? context),
                    Positioned(
                      top: (navigationTop ?? navigationTopFallback) +
                          navigationTopOffset,
                      left: navigationLeftOffset,
                      child: InkWell(
                        onTap: () => setState(() {
                          isDrawerOpen = false;
                          scaffoldKey.currentState?.openEndDrawer();
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
