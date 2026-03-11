import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/layout/editable_multiline_text.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/switch_button.dart';
import 'package:roonmatrix/ui/layout/vertical_radio_selector.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class MessageWriter extends StatefulWidget {
  final String ip;
  final bool isPortraitMode;
  final String customMessage;
  final Map<String, dynamic> translations;
  final Widget? deviceSelection;

  const MessageWriter({
    super.key,
    required this.ip,
    required this.isPortraitMode,
    required this.customMessage,
    required this.translations,
    this.deviceSelection,
  });

  @override
  State<MessageWriter> createState() => MessageWriterState();
}

class MessageWriterState extends State<MessageWriter> {
  String get ip => widget.ip;
  bool get isPortraitMode => widget.isPortraitMode;
  String get customMessage => widget.customMessage;
  Map<String, dynamic> get translations => widget.translations;
  Widget? get deviceSelection => widget.deviceSelection;

  Widget get textAreaWithButtons => getTextAreaWithButtons();
  bool get isPortraiModeChanged => isPortraitMode != isPortraitModeBefore;

  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController messageTextController = TextEditingController();
  final ValueNotifier<String> messageTextBackup = ValueNotifier<String>('');

  String? selectedMessageId;
  Map<String, String> options = {};
  String selectedOption = '';
  bool optionsLoaded = false;
  bool setMessage = false;
  bool allDevices = false;
  bool isPortraitModeBefore = false;

  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    init();

    super.initState();
  }

  init() async {
    Map<String, String> options = await getCustomMessages();
    if (customMessage.isNotEmpty) {
      String? key = options.entries
          .firstWhereOrNull((MapEntry entry) => entry.value == customMessage)
          ?.key;
      selectedMessageId = key;

      messageTextController.text = customMessage;
      messageTextBackup.value = customMessage;
    }
  }

  @override
  void didUpdateWidget(MessageWriter oldWidget) {
    if (messageTextController.text.isEmpty &&
            messageTextBackup.value.isNotEmpty ||
        isPortraiModeChanged) {
      isPortraitModeBefore = isPortraitMode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          final value = messageTextBackup.value;

          messageTextController.value = messageTextController.value.copyWith(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
            composing: TextRange.empty,
          );
        });
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    nameTextController.dispose();
    messageTextController.dispose();
    messageTextBackup.dispose();

    super.dispose();
  }

  Future<Map<String, String>> getCustomMessages() async {
    options = await mainRepository.getCustomMessages();
    setState(() {
      optionsLoaded = true;
    });

    return options;
  }

  Widget messageSelectbox() => Padding(
        padding: EdgeInsets.only(bottom: Globals.isMobileDevice() ? 0.0 : 8.0),
        child: SelectBox(
            translations: translations,
            aligned: 'horizontal',
            label: '${translations['messageSelectionLabel'] ?? 'Message'}:',
            placeholder:
                '${translations['messageSelectionPlaceholder'] ?? 'Select Message'}...',
            noVerticalSpace: true,
            selected: selectedMessageId,
            options: options,
            expanded: true,
            elementExpanded: true,
            onChanged: (String? newValue) {
              messageTextBackup.value = options[newValue]!;
              setState(() {
                selectedMessageId = newValue;
                messageTextController.text = options[selectedMessageId]!;
              });
            }),
      );

  Widget stopMessageButton({required bool desktopLandscapeWide}) => Padding(
        padding: EdgeInsets.only(
            top: Globals.inMacosStyle()
                ? 15.0
                : deviceSelection == null
                    ? 19.0
                    : 0,
            right: 16.0),
        child: IconTextButtonElement(
          onMacAsText: true,
          icon: const Padding(
            padding: EdgeInsets.symmetric(vertical: 7.5),
            child: Icon(
              FontAwesomeIcons.circleStop,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          label: desktopLandscapeWide
              ? translations['breakMessageButtonLabel'] ?? 'stop message'
              : translations['breakMessageShortButtonLabel'] ?? 'stop',
          onPressed: customMessage.isEmpty
              ? null
              : () async {
                  if (Platform.isIOS || Platform.isAndroid) {
                    FocusManager.instance.primaryFocus
                        ?.unfocus(); // hide onscreen keyboard to see the response message (snackbar)
                  }
                  selectedOption = '';
                  bool value = await SharedWidgets.showPlatformSpecificDialog(
                    context: context,
                    child: (BuildContext context) =>
                        StatefulBuilder(builder: (context, setState) {
                      return AlertElement(
                        title: translations['dialogResetMessageQuestion'] ??
                            'Do you really want to remove this message from the device?',
                        content: SizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 48.0),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: Globals.inMacosStyle() ? 8.0 : 0.0),
                                child: SwitchButton(
                                  aligned: 'inline',
                                  reverse: true,
                                  label: translations[
                                          'allDevicesRemoveSwitchLabel'] ??
                                      'remove from all devices',
                                  enabled: allDevices,
                                  expanded: false,
                                  onChanged: (bool value) {
                                    if (mounted) {
                                      setState(() => allDevices = value);
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                        button1Label: translations['dialogNo'] ?? 'No',
                        onPressed1: () => Navigator.of(context).pop(false),
                        button2Label: translations['dialogYes'] ?? 'Yes',
                        onPressed2: () => Navigator.of(context).pop(true),
                      );
                    }),
                  );

                  if (value == true) {
                    bool valid = false;
                    Map<String, dynamic> info = mainBloc.state.info;

                    if (allDevices == true) {
                      List<String> devices = mainBloc.state.devices;
                      for (String device in devices) {
                        valid = await mainBloc.setCustomMessage(
                            ip: device, message: '', option: 'stop');
                        mainBloc.getInfo(ip: ip);

                        String name = info[device]?['name'] ?? device;
                        String doneMessage =
                            translations['messageRemoveDoneMessage'] != null
                                ? (translations['messageRemoveDoneMessage']
                                        as String)
                                    .replaceFirst('#', name)
                                : "remove message from $name successfully done";
                        String failMessage =
                            translations['messageRemoveFailedMessage'] != null
                                ? (translations['messageRemoveFailedMessage']
                                        as String)
                                    .replaceFirst('#', name)
                                : "remove message from $name is failed!";

                        SharedWidgets.showSnackBar(
                            // ignore: use_build_context_synchronously
                            context: context,
                            doneMessage: doneMessage,
                            failMessage: failMessage,
                            valid: valid);
                      }
                    } else {
                      valid = await mainBloc.setCustomMessage(
                          ip: ip, message: '', option: 'stop');
                      mainBloc.getInfo(ip: ip);
                      nameTextController.text = '';
                      messageTextController.text = '';
                      messageTextBackup.value = messageTextController.text;
                      selectedMessageId = null;

                      String name = info[ip]?['name'] ?? ip;
                      String doneMessage =
                          translations['messageRemoveDoneMessage'] != null
                              ? (translations['messageRemoveDoneMessage']
                                      as String)
                                  .replaceFirst('#', name)
                              : "remove message from $name successfully done";
                      String failMessage =
                          translations['messageRemoveFailedMessage'] != null
                              ? (translations['messageRemoveFailedMessage']
                                      as String)
                                  .replaceFirst('#', name)
                              : "remove message from $name is failed!";

                      SharedWidgets.showSnackBar(
                          // ignore: use_build_context_synchronously
                          context: context,
                          doneMessage: doneMessage,
                          failMessage: failMessage,
                          valid: valid);
                    }
                  }
                },
        ),
      );

  Widget sendMessageButton() => Padding(
        padding: EdgeInsets.only(
            top: Globals.inMacosStyle()
                ? 15.0
                : deviceSelection == null
                    ? 19.0
                    : 0,
            right: 16.0),
        child: ValueListenableBuilder<String>(
            valueListenable: messageTextBackup,
            builder: (BuildContext context, String value, child) {
              return IconTextButtonElement(
                onMacAsText: true,
                icon: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7.5),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
                label: (translations['sendButtonLabel'] ?? 'send')
                    .toString()
                    .toFirstUpper,
                onPressed: messageTextBackup.value.isEmpty ||
                        (customMessage.isNotEmpty &&
                            customMessage == messageTextBackup.value)
                    ? null
                    : () async {
                        if (Platform.isIOS || Platform.isAndroid) {
                          FocusManager.instance.primaryFocus
                              ?.unfocus(); // hide onscreen keyboard to see the response message (snackbar)
                        }
                        selectedOption = '';
                        bool value =
                            await SharedWidgets.showPlatformSpecificDialog(
                          context: context,
                          child: (BuildContext context) =>
                              StatefulBuilder(builder: (context, setState) {
                            return AlertElement(
                              title: translations['dialogSendQuestion'] ??
                                  'Do you really want to send this message to the device?',
                              content: SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    VerticalRadioSelector(
                                      options: [
                                        translations['sendOptionForce'] ??
                                            'Force Playout',
                                        translations['sendOptionNextPlayout'] ??
                                            'On next Playout',
                                        translations['sendOptionExclusive'] ??
                                            'Exclusive Playout'
                                      ],
                                      selectedOption: null,
                                      onChanged: (String? value) {
                                        setState(() {
                                          selectedOption = value!;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 48.0),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: Globals.inMacosStyle()
                                              ? 8.0
                                              : 0.0),
                                      child: SwitchButton(
                                        aligned: 'inline',
                                        reverse: true,
                                        label: translations[
                                                'allDevicesSwitchLabel'] ??
                                            'send to all devices',
                                        enabled: allDevices,
                                        expanded: false,
                                        onChanged: (bool value) {
                                          if (mounted) {
                                            setState(() => allDevices = value);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              button1Label: translations['dialogNo'] ?? 'No',
                              onPressed1: () =>
                                  Navigator.of(context).pop(false),
                              button2Label: translations['dialogYes'] ?? 'Yes',
                              onPressed2: selectedOption.isNotEmpty
                                  ? () => Navigator.of(context).pop(true)
                                  : null,
                            );
                          }),
                        );
                        if (value == true) {
                          setState(() {
                            setMessage = true;
                          });

                          bool valid = false;
                          Map<String, dynamic> info = mainBloc.state.info;

                          if (allDevices == true) {
                            List<String> devices = mainBloc.state.devices;
                            for (String device in devices) {
                              valid = await mainBloc.setCustomMessage(
                                  ip: device,
                                  message: messageTextBackup.value,
                                  option: mainRepository
                                      .getSelectedPlayoutOptionKey(
                                    option: selectedOption,
                                    translations: translations,
                                  ));
                              mainBloc.getInfo(ip: ip);

                              String name = info[device]?['name'] ?? device;
                              String doneMessage = translations[
                                          'messageDoneMessage'] !=
                                      null
                                  ? (translations['messageDoneMessage']
                                          as String)
                                      .replaceFirst('#', name)
                                  : "send message to $name successfully done";
                              String failMessage =
                                  translations['messageFailedMessage'] != null
                                      ? (translations['messageFailedMessage']
                                              as String)
                                          .replaceFirst('#', name)
                                      : "send message to $name failed!";

                              SharedWidgets.showSnackBar(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  doneMessage: doneMessage,
                                  failMessage: failMessage,
                                  valid: valid);
                            }
                          } else {
                            valid = await mainBloc.setCustomMessage(
                                ip: ip,
                                message: messageTextBackup.value,
                                option:
                                    mainRepository.getSelectedPlayoutOptionKey(
                                  option: selectedOption,
                                  translations: translations,
                                ));
                            mainBloc.getInfo(ip: ip);

                            String name = info[ip]?['name'] ?? ip;
                            String doneMessage =
                                translations['messageDoneMessage'] != null
                                    ? (translations['messageDoneMessage']
                                            as String)
                                        .replaceFirst('#', name)
                                    : "send message to $name successfully done";
                            String failMessage =
                                translations['messageFailedMessage'] != null
                                    ? (translations['messageFailedMessage']
                                            as String)
                                        .replaceFirst('#', name)
                                    : "send message to $name failed!";

                            SharedWidgets.showSnackBar(
                                // ignore: use_build_context_synchronously
                                context: context,
                                doneMessage: doneMessage,
                                failMessage: failMessage,
                                valid: valid);
                          }

                          setState(() {
                            setMessage = false;
                            nameTextController.text = '';
                          });
                        }
                      },
              );
            }),
      );

  void onAddMessagePreset({required String key}) => options.containsKey(key)
      ? ApproveModal(
          context: context,
          title:
              translations['removeMessageNameExistTitle'] ?? "Remove message",
          question:
              '${translations['removeMessageNameExistQuestion'] ?? 'This message name is in use'}!',
          okText: translations['okButtonText'] ?? 'OK',
          cancelText: '',
          onApproved: () => setState(() {
            nameTextController.text = '';
          }),
          onCanceled: () => setState(() {
            nameTextController.text = '';
          }),
        ).show()
      : setState(() {
          options.putIfAbsent(key, () => messageTextController.text);
          nameTextController.text = '';
          messageTextController.text = '';
          messageTextBackup.value = messageTextController.text;
          mainRepository.setCustomMessages(messages: options);
          mainBloc.getInfo(ip: ip);
        });

  Future<void> onRemoveMessagePreset() async {
    if (selectedMessageId != null && options.containsKey(selectedMessageId)) {
      bool value = await SharedWidgets.showPlatformSpecificDialog(
        context: context,
        child: (BuildContext context) =>
            StatefulBuilder(builder: (context, setState) {
          return AlertElement(
            title: translations['dialogRemoveMessageQuestion'] ??
                'Do you really want to delete this message?',
            button1Label: translations['dialogNo'] ?? 'No',
            onPressed1: () => Navigator.of(context).pop(false),
            button2Label: translations['dialogYes'] ?? 'Yes',
            onPressed2: () => Navigator.of(context).pop(true),
          );
        }),
      );
      if (value == true) {
        setState(() {
          String key = selectedMessageId!;
          nameTextController.text = '';
          messageTextController.text = '';
          messageTextBackup.value = messageTextController.text;
          selectedMessageId = null;
          options.remove(key);
          mainRepository.setCustomMessages(messages: options);
          mainBloc.getInfo(ip: ip);
        });
      }
    }
  }

  Widget getTextAreaWithButtons() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              double textFieldHeight =
                  constraints.maxHeight - (Globals.isMobileDevice() ? 3 : 0);
              double fontSize = textFieldHeight / 20 / 1.25;

              return EditableMultilineText(
                key: const PageStorageKey("message_text_field"),
                translations: translations,
                height: textFieldHeight,
                fontSize: fontSize > 16 ? fontSize : 16,
                textController: messageTextController,
                withDebounce: false,
                onChanged: (String value) {
                  if (messageTextBackup.value != value) {
                    messageTextBackup.value = value;
                  }
                },
              );
            }),
          ),
          ValueListenableBuilder<String>(
              valueListenable: messageTextBackup,
              builder: (BuildContext context, String value, child) {
                return Padding(
                  padding: EdgeInsets.only(right: isPortraitMode ? 16.0 : 0.0),
                  child: Container(
                    decoration: ShapeDecoration(
                      color:
                          ColorDefs.buttonAreaBackgroundColor(context: context),
                      shape: RoundedRectangleBorder(
                        borderRadius: Globals.borderRadius(),
                      ),
                    ),
                    child: Column(
                      children: [
                        Tooltip(
                          message: translations['addMessageToPresetsLabel'] ??
                              'Add message to presets list',
                          waitDuration: Globals.tooltipWaitDuration,
                          child: Ink(
                            decoration: ShapeDecoration(
                              color: messageTextBackup.value.isNotEmpty
                                  ? Globals.brightness() == Brightness.dark
                                      ? Colors.blue.shade800
                                      : Colors.blue.shade600
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: Globals.borderRadius(),
                              ),
                            ),
                            child: SharedWidgets.addIconButton(
                                context: context,
                                textController: nameTextController,
                                disabled: messageTextBackup.value.isEmpty,
                                translations: translations,
                                onExit: () => setState(() {
                                      nameTextController.text = '';
                                    }),
                                onAccepted: (dynamic newKey) {
                                  if (newKey is String && newKey.isNotEmpty) {
                                    onAddMessagePreset(key: newKey);
                                  }
                                }),
                          ),
                        ),
                        Expanded(child: const SizedBox(height: 5.0)),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: (Globals.isDesktopDevice() ? 0.0 : 21.0) -
                                (Globals.isMobileDevice() ? 19 : 0),
                          ),
                          child: Tooltip(
                            message:
                                translations['removeMessageFromPresetsLabel'] ??
                                    'Remove message from presets list',
                            waitDuration: Globals.tooltipWaitDuration,
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: selectedMessageId != null &&
                                        options.containsKey(selectedMessageId)
                                    ? Globals.brightness() == Brightness.dark
                                        ? Colors.blue.shade800
                                        : Colors.blue.shade600
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: Globals.borderRadius(),
                                ),
                              ),
                              child: SharedWidgets.removeIconButton(
                                context: context,
                                textController: nameTextController,
                                disabled: selectedMessageId == null,
                                translations: translations,
                                onPressed: () => onRemoveMessagePreset(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      child: optionsLoaded == true
          ? isPortraitMode
              ? Column(
                  children: [
                    if (deviceSelection != null) deviceSelection!,
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: messageSelectbox(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 8.0,
                        bottom: Globals.isMobileDevice() ? 0.0 : 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: stopMessageButton(
                                desktopLandscapeWide:
                                    Globals.isDesktopDevice()),
                          ),
                          sendMessageButton(),
                        ],
                      ),
                    ),
                    Expanded(
                        child: Container(
                      margin: Globals.isDesktopDevice()
                          ? EdgeInsets.only(
                              top: 16.0,
                              bottom: 16.0,
                              right: isPortraitMode ? 0.0 : 16.0,
                            )
                          : EdgeInsets.only(top: isPortraitMode ? 8.0 : 0.0),
                      child: textAreaWithButtons,
                    )),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              margin: EdgeInsets.only(
                                  left: Globals.isDesktopDevice() ? 16.0 : 0.0,
                                  top: Globals.isDesktopDevice() ? 16.0 : 0.0,
                                  bottom:
                                      Globals.isDesktopDevice() ? 16.0 : 3.0),
                              decoration: BoxDecoration(
                                borderRadius: Globals.borderRadius(),
                                border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 0,
                                    style: BorderStyle.solid),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12.0),
                                  if (deviceSelection != null) deviceSelection!,
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: messageSelectbox(),
                                  ),
                                  MediaQuery.of(context).size.width <
                                          Globals.widthSwitchBoundaryMid
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 16.0,
                                                        top: Globals
                                                                .isMobileDevice()
                                                            ? 16.0
                                                            : 8.0),
                                                    child: stopMessageButton(
                                                        desktopLandscapeWide:
                                                            Globals
                                                                .isDesktopDevice()),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 16.0,
                                                            top: 8.0),
                                                    child: sendMessageButton(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  left: 16.0,
                                                  top: Globals.isMobileDevice()
                                                      ? 16.0
                                                      : 8.0),
                                              child: stopMessageButton(
                                                  desktopLandscapeWide: Globals
                                                      .isDesktopDevice()),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: Globals.isMobileDevice()
                                                      ? 16.0
                                                      : 8.0),
                                              child: sendMessageButton(),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),
                          Flexible(
                            child: Container(
                              margin: Globals.isDesktopDevice()
                                  ? EdgeInsets.only(
                                      top: 16.0,
                                      bottom: 16.0,
                                      right: isPortraitMode ? 0.0 : 16.0,
                                    )
                                  : EdgeInsets.only(
                                      top: isPortraitMode ? 8.0 : 0.0),
                              child: textAreaWithButtons,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
          : const SizedBox(),
    );
  }
}
