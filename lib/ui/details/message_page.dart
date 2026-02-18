import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/message_writer.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class MessagePage extends StatefulWidget {
  final String name;
  final String ip;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const MessagePage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<String> messageTextBackup = ValueNotifier<String>('');
  TextEditingController messageTextController = TextEditingController();

  Map<String, dynamic> translations = {};
  String title = '';
  String macosVersion = '';
  bool translationsLoaded = false;

  String? selectedDeviceName;
  String customMessage = '';

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late String selectedDeviceIp;

  @override
  void initState() {
    title = '$name : Control';
    selectedDeviceIp = ip;

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: selectedDeviceIp);

    super.initState();
  }

  @override
  void dispose() {
    messageTextController.dispose();

    super.dispose();
  }

  Widget selectBox({
    required Map<String, String> options,
  }) {
    if (selectedDeviceName == null || options[selectedDeviceName] == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      return SizedBox();
    }

    return SelectBox(
        translations: translations,
        aligned: 'horizontal',
        label: '${translations['deviceName'] ?? 'device name'}:',
        placeholder:
            '${translations['deviceSelectionPlaceholder'] ?? 'Select device'}...',
        inRow: false,
        noVerticalSpace: Globals.isMobileDevice(),
        readOnly: false,
        expanded: true,
        selected: selectedDeviceName,
        options: options,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedDeviceName = newValue;
              selectedDeviceIp = options[newValue]!;
            });
          }
        });
  }

  Widget body({
    required bool isPortraitMode,
    required Map<String, String> options,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Center(
          child: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: MessageWriter(
          key: const ValueKey('message_writer'),
          ip: selectedDeviceIp,
          isPortraitMode: isPortraitMode,
          messageTextController: messageTextController,
          messageTextBackup: messageTextBackup,
          customMessage: customMessage,
          translations: translations,
          deviceSelection: selectBox(options: options),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
            title =
                '$name : ${translations['messagePageHeaderText'] ?? 'Message'}';
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
            if (Globals.inIosStyle()) {
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  brightness: Globals.brightness(),
                  middle: Text(title),
                ),
                child: SizedBox(),
              );
            }
            return Globals.inMacosStyle()
                ? MacosScaffold(
                    toolBar: ToolBar(
                      title: Text(
                        title,
                        style: TextStyle(
                          color: ColorDefs.textColor(context: context),
                        ),
                      ),
                      titleWidth: Globals.extendedTitleWidth,
                      leading: MacosBackButton(
                        onPressed: () => Navigator.pop(context),
                        fillColor: Colors.transparent,
                      ),
                      actions: [],
                    ),
                    children: [
                      ContentArea(
                        builder: ((context, scrollController) {
                          return MacosWindow(
                            child: Material(
                              child: SizedBox(),
                            ),
                          );
                        }),
                      ),
                    ],
                  )
                : Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                    ),
                    body: const SizedBox());
          }

          return BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return const SizedBox();
                }

                macosVersion = mainState.macosVersion;
                List<String> devices = mainState.devices;
                Map<String, dynamic> infos = mainState.info;
                Map<String, dynamic> info = infos[selectedDeviceIp] ?? {};
                selectedDeviceName = info['name'];
                customMessage = info['custom_message'];
                Map<String, String> options = mainBloc.generateDeviceOptions(
                  devices: devices,
                  infos: infos,
                );

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  bool isPortraitMode = orientation == Orientation.portrait;

                  if (Globals.inIosStyle()) {
                    return Material(
                      child: CupertinoPageScaffold(
                        navigationBar: CupertinoNavigationBar(
                          brightness: Globals.brightness(),
                          middle: Text(title),
                          leading: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: CupertinoNavigationBarBackButton(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        child: SafeArea(
                          child: body(
                              isPortraitMode: isPortraitMode, options: options),
                        ),
                      ),
                    );
                  }

                  return Globals.inMacosStyle()
                      ? PageWithToolbarMacStyle(
                          title: title,
                          standardDesktopSize: standardDesktopSize,
                          macosVersion: macosVersion,
                          body: body(
                              isPortraitMode: isPortraitMode, options: options),
                          resizeToFullWidth: () {
                            mainBloc.windowResizeToFullWidthAndMinimumHeight(
                                minDesktopSize: minDesktopSize);
                          },
                        )
                      : PageWithToolbarFlutterStyle(
                          scaffoldKey: scaffoldKey,
                          title: title,
                          showExpandableSpeedSlider: false,
                          scrollSpeedDevice: 1.0,
                          standardDesktopSize: standardDesktopSize,
                          body: body(
                              isPortraitMode: isPortraitMode, options: options),
                          resizeToFullWidth: () {
                            mainBloc.windowResizeToFullWidthAndMinimumHeight(
                                minDesktopSize: minDesktopSize);
                          },
                        );
                });
              });
        });
  }
}
