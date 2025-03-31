import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/layout/editable_multiline_text.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/switch_element.dart';
import 'package:roonmatrix/ui/layout/vertical_radio_selector.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class MessageWriter extends StatefulWidget {
  final String name;
  final String ip;
  final String customMessage;
  final Map<String, dynamic> translations;
  final Widget? firstRowChild;

  const MessageWriter({
    super.key,
    required this.name,
    required this.ip,
    required this.customMessage,
    required this.translations,
    this.firstRowChild,
  });

  @override
  State<MessageWriter> createState() => MessageWriterState();
}

class MessageWriterState extends State<MessageWriter> {
  String get name => widget.name;
  String get ip => widget.ip;
  Map<String, dynamic> get translations => widget.translations;
  TextEditingController nameTextController = TextEditingController();
  TextEditingController messageTextController = TextEditingController();

  String? selectedMessageId;
  Map<String, String> options = {};
  String selectedOption = '';
  bool optionsLoaded = false;
  bool setMessage = false;
  bool allDevices = false;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    getCustomMessages();

    super.initState();
  }

  Future<void> getCustomMessages() async {
    options = await mainBloc.getCustomMessages();
    setState(() {
      optionsLoaded = true;
    });
  }

  @override
  void dispose() {
    nameTextController.dispose();
    messageTextController.dispose();
    super.dispose();
  }

  String getSelectedOptionKey(String option) {
    if (option == translations['sendOptionForce'] ||
        option == 'Force Playout') {
      return 'force';
    }
    if (option == translations['sendOptionNextPlayout'] ||
        option == 'On next Playout') {
      return 'playout';
    }
    if (option == translations['sendOptionExclusive'] ||
        option == 'Exclusive Playout') {
      return 'exclusive';
    }

    return 'playout';
  }

  Widget selectbox() => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SelectBox(
            translations: translations,
            aligned: 'horizontal',
            label: '${translations['messageSelectionLabel'] ?? 'Message'}:',
            placeholder:
                '${translations['messageSelectionPlaceholder'] ?? 'Select Message'}...',
            noVerticalSpace: true,
            selected: selectedMessageId,
            options: options,
            onChanged: (String? newValue) {
              setState(() {
                selectedMessageId = newValue;
                messageTextController.text = options[selectedMessageId]!;
              });
            }),
      );

  Widget labelWidget(String? label, Color? labelColor) => Expanded(
        child: label != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: SharedWidgets.brightness() == Brightness.dark
                        ? SharedWidgets.textColor(context: context)
                        : labelColor ??
                            SharedWidgets.textColor(context: context),
                    fontSize: 12.0,
                  ),
                ),
              )
            : Container(),
      );

  Widget switchButton({
    required bool value,
    required String label,
    required Function(bool value) onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.all(0),
        alignment: Alignment.topLeft,
        transform: Matrix4.translationValues(-9.0, -0.0, 0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              transform: Matrix4.translationValues(10.0, -0.0, 0.0),
              child: SwitchElement(
                value: value,
                onChanged: onChanged,
              ),
            ),
            labelWidget(label, null)
          ],
        ),
      );

  Widget stopMessageButton({required bool desktopLandscapeWide}) => Padding(
        padding: EdgeInsets.only(
            top: SharedWidgets.inMacosStyle()
                ? 15.0
                : widget.firstRowChild == null
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
          onPressed: widget.customMessage.isEmpty
              ? null
              : () async {
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
                              switchButton(
                                value: allDevices,
                                label: translations[
                                        'allDevicesRemoveSwitchLabel'] ??
                                    'remove from all devices',
                                onChanged: (bool value) {
                                  if (mounted) {
                                    setState(() => allDevices = value);
                                  }
                                },
                              ),

                              // SwitchButton(
                              //   label: translations[
                              //           'allDevicesRemoveSwitchLabel'] ??
                              //       'remove from all devices',
                              //   labelColor: Colors.black,
                              //   reverse: true,
                              //   enabled: allDevices,
                              //   onChanged: (bool value) {
                              //     if (mounted) {
                              //       setState(() => allDevices = value);
                              //     }
                              //   },
                              // ),
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
            top: SharedWidgets.inMacosStyle()
                ? 15.0
                : widget.firstRowChild == null
                    ? 19.0
                    : 0,
            right: 16.0),
        child: IconTextButtonElement(
          onMacAsText: true,
          icon: const Padding(
            padding: EdgeInsets.symmetric(vertical: 7.5),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          label: translations['sendButtonLabel'] ?? 'send',
          onPressed: messageTextController.text.isEmpty ||
                  (widget.customMessage.isNotEmpty &&
                      widget.customMessage == messageTextController.text)
              ? null
              : () async {
                  selectedOption = '';
                  bool value = await SharedWidgets.showPlatformSpecificDialog(
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
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 0.0),
                                  child: switchButton(
                                    value: allDevices,
                                    label:
                                        translations['allDevicesSwitchLabel'] ??
                                            'send to all devices',
                                    onChanged: (bool value) {
                                      if (mounted) {
                                        setState(() => allDevices = value);
                                      }
                                    },
                                  ),

                                  //     SwitchButton(
                                  //   label: translations[
                                  //           'allDevicesSwitchLabel'] ??
                                  //       'send to all devices',
                                  //   reverse: true,
                                  //   enabled: allDevices,
                                  //   onChanged: (bool value) {
                                  //     if (mounted) {
                                  //       setState(() => allDevices = value);
                                  //     }
                                  //   },
                                  // ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        button1Label: translations['dialogNo'] ?? 'No',
                        onPressed1: () => Navigator.of(context).pop(false),
                        button2Label: translations['dialogYes'] ?? 'Yes',
                        onPressed2: selectedOption.isNotEmpty
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        // actions: [
                        //   Padding(
                        //     padding: const EdgeInsets.only(bottom: 16.0),
                        //     child: ElevatedButton(
                        //         style: ButtonStyle(
                        //           backgroundColor: WidgetStateProperty
                        //               .resolveWith<Color>(
                        //             (Set<WidgetState> states) {
                        //               return Colors.blueGrey;
                        //             },
                        //           ),
                        //         ),
                        //         onPressed: () =>
                        //             Navigator.of(context).pop(false),
                        //         child: Text(
                        //             translations['dialogNo'] ?? 'No')),
                        //   ),
                        //   Padding(
                        //     padding: const EdgeInsets.only(
                        //         bottom: 16.0, left: 16.0, right: 16.0),
                        //     child: ElevatedButton(
                        //         key: ValueKey('SendOption$selectedOption'),
                        //         onPressed: selectedOption.isNotEmpty
                        //             ? () => Navigator.of(context).pop(true)
                        //             : null,
                        //         child: Text(translations['dialogYes'] ??
                        //             'Yes')),
                        //   ),
                        // ],
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
                            message: messageTextController.text,
                            option: getSelectedOptionKey(selectedOption));
                        mainBloc.getInfo(ip: ip);

                        String name = info[device]?['name'] ?? device;
                        String doneMessage =
                            translations['messageDoneMessage'] != null
                                ? (translations['messageDoneMessage'] as String)
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
                          message: messageTextController.text,
                          option: getSelectedOptionKey(selectedOption));
                      mainBloc.getInfo(ip: ip);

                      String name = info[ip]?['name'] ?? ip;
                      String doneMessage =
                          translations['messageDoneMessage'] != null
                              ? (translations['messageDoneMessage'] as String)
                                  .replaceFirst('#', name)
                              : "send message to $name successfully done";
                      String failMessage =
                          translations['messageFailedMessage'] != null
                              ? (translations['messageFailedMessage'] as String)
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
                      selectedMessageId = null;
                    });
                  }
                },
        ),
      );

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool desktopLandscapeWide =
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux) &&
            width >= 800;

    return optionsLoaded == true
        ? Column(
            children: [
              if (desktopLandscapeWide == true)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SharedWidgets.inMacosStyle()
                        ? selectbox()
                        : Expanded(child: selectbox()),
                    Padding(
                      padding: EdgeInsets.only(
                          top: SharedWidgets.inMacosStyle()
                              ? 6.0
                              : SharedWidgets.inIosStyle()
                                  ? 12.0
                                  : 0.0),
                      child: stopMessageButton(
                          desktopLandscapeWide: desktopLandscapeWide),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: SharedWidgets.inMacosStyle()
                              ? 6.0
                              : SharedWidgets.inIosStyle()
                                  ? 12.0
                                  : 0.0),
                      child: sendMessageButton(),
                    ),
                  ],
                ),
              if (!desktopLandscapeWide) ...[
                Row(mainAxisSize: MainAxisSize.max, children: [
                  if (widget.firstRowChild != null)
                    Expanded(child: widget.firstRowChild!),
                  selectbox(),
                ]),
                if (widget.firstRowChild != null) const SizedBox(height: 16.0),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: stopMessageButton(
                          desktopLandscapeWide: desktopLandscapeWide),
                    ),
                    sendMessageButton(),
                  ],
                ),
                const SizedBox(height: 16.0),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: EditableMultilineText(
                      translations: translations,
                      label:
                          '${translations['messageNewLabel'] ?? 'New message'}:',
                      maxLines: 5,
                      height: SharedWidgets.inIosStyle() || Platform.isAndroid
                          ? 101.0
                          : 86.0,
                      textController: messageTextController,
                      onChanged: (String value) {
                        if (mounted) {
                          setState(() => messageTextController.text = value);
                        }
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        top: SharedWidgets.inIosStyle() ||
                                SharedWidgets.inMacosStyle()
                            ? 22.0
                            : 18.0),
                    padding: const EdgeInsets.only(right: 16.0, left: 4.0),
                    child: Column(
                      children: [
                        Ink(
                          decoration: ShapeDecoration(
                            color: messageTextController.text.isNotEmpty
                                ? SharedWidgets.brightness() == Brightness.dark
                                    ? Colors.blue.shade800
                                    : Colors.blue.shade600
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(
                                  SharedWidgets.inIosStyle() ? 8 : 5)),
                            ),
                          ),
                          child: SharedWidgets.addIconButton(
                              context: context,
                              textController: nameTextController,
                              disabled: messageTextController.text.isEmpty,
                              translations: translations,
                              onExit: () => setState(() {
                                    nameTextController.text = '';
                                  }),
                              onAccepted: (dynamic newKey) {
                                if (newKey is String && newKey.isNotEmpty) {
                                  if (options.containsKey(newKey)) {
                                    ApproveModal(
                                      context: context,
                                      title: translations[
                                              'removeMessageNameExistTitle'] ??
                                          "Remove message",
                                      question:
                                          '${translations['removeMessageNameExistQuestion'] ?? 'This message name is in use'}!',
                                      okText:
                                          translations['okButtonText'] ?? 'OK',
                                      cancelText: '',
                                      onApproved: () => setState(() {
                                        nameTextController.text = '';
                                      }),
                                      onCanceled: () => setState(() {
                                        nameTextController.text = '';
                                      }),
                                    ).show();
                                  } else {
                                    setState(() {
                                      options.putIfAbsent(newKey,
                                          () => messageTextController.text);
                                      nameTextController.text = '';
                                      messageTextController.text = '';
                                      mainBloc.setCustomMessages(
                                          messages: options);
                                      mainBloc.getInfo(ip: ip);
                                    });
                                  }
                                }
                              }),
                        ),
                        const SizedBox(height: 5.0),
                        Ink(
                          padding: EdgeInsets.all(0.0),
                          decoration: ShapeDecoration(
                            color: selectedMessageId != null &&
                                    options.containsKey(selectedMessageId)
                                ? SharedWidgets.brightness() == Brightness.dark
                                    ? Colors.blue.shade800
                                    : Colors.blue.shade600
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(
                                  SharedWidgets.inIosStyle() ? 8 : 5)),
                            ),
                          ),
                          child: SharedWidgets.removeIconButton(
                            context: context,
                            textController: nameTextController,
                            disabled: selectedMessageId == null,
                            translations: translations,
                            onPressed: () async {
                              if (selectedMessageId != null &&
                                  options.containsKey(selectedMessageId)) {
                                bool value = await SharedWidgets
                                    .showPlatformSpecificDialog(
                                  context: context,
                                  child: (BuildContext context) =>
                                      StatefulBuilder(
                                          builder: (context, setState) {
                                    return AlertElement(
                                      title: translations[
                                              'dialogRemoveMessageQuestion'] ??
                                          'Do you really want to delete this message?',
                                      button1Label:
                                          translations['dialogNo'] ?? 'No',
                                      onPressed1: () =>
                                          Navigator.of(context).pop(false),
                                      button2Label:
                                          translations['dialogYes'] ?? 'Yes',
                                      onPressed2: () =>
                                          Navigator.of(context).pop(true),
                                    );
                                  }),
                                );
                                if (value == true) {
                                  setState(() {
                                    String key = selectedMessageId!;
                                    nameTextController.text = '';
                                    messageTextController.text = '';
                                    selectedMessageId = null;
                                    options.remove(key);
                                    mainBloc.setCustomMessages(
                                        messages: options);
                                    mainBloc.getInfo(ip: ip);
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          )
        : const SizedBox();
  }
}
