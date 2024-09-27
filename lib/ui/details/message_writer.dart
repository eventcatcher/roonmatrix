import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/layout/editable_multiline_text.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/vertical_radio_selector.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class MessageWriter extends StatefulWidget {
  final String name;
  final String ip;
  final Map<String, dynamic> translations;

  const MessageWriter({
    super.key,
    required this.name,
    required this.ip,
    required this.translations,
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

  Widget stopMessageButton({required bool desktopLandscapeWide}) => Padding(
        padding: const EdgeInsets.only(top: 19.0, right: 16.0),
        child: ElevatedButton.icon(
          icon: const Padding(
            padding: EdgeInsets.symmetric(vertical: 7.5),
            child: Icon(
              FontAwesomeIcons.circleStop,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          label: desktopLandscapeWide
              ? Text(translations['breakMessageButtonLabel'] ?? 'stop message')
              : Text(translations['breakMessageShortButtonLabel'] ?? 'stop'),
          onPressed: messageTextController.text.isNotEmpty
              ? () async {
                  mainBloc.setCustomMessage(
                      ip: ip, message: '', option: 'stop');
                  nameTextController.text = '';
                  messageTextController.text = '';
                  selectedMessageId = null;
                }
              : null,
        ),
      );

  Widget sendMessageButton() => Padding(
        padding: const EdgeInsets.only(top: 19.0, right: 16.0),
        child: ElevatedButton.icon(
          icon: const Padding(
            padding: EdgeInsets.symmetric(vertical: 7.5),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          label: Text(translations['sendButtonLabel'] ?? 'send'),
          onPressed: messageTextController.text.isNotEmpty
              ? () async {
                  selectedOption = '';
                  dynamic value = await showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(builder: (context, setState) {
                          return AlertDialog(
                              title: Text(translations['dialogSendQuestion'] ??
                                  'Do you really want to send this message to the device?'),
                              content: VerticalRadioSelector(
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
                              actions: [
                                ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty
                                          .resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          return Colors.blueGrey;
                                        },
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                        translations['dialogQuitNo'] ?? 'No')),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: ElevatedButton(
                                      key:
                                          ValueKey('SendOption$selectedOption'),
                                      onPressed: selectedOption.isNotEmpty
                                          ? () =>
                                              Navigator.of(context).pop(true)
                                          : null,
                                      child: Text(
                                          translations['dialogQuitYes'] ??
                                              'Yes')),
                                ),
                              ]);
                        });
                      });
                  if (value == true) {
                    mainBloc.setCustomMessage(
                        ip: ip,
                        message: messageTextController.text,
                        option: getSelectedOptionKey(selectedOption));
                    nameTextController.text = '';
                    selectedMessageId = null;
                  }
                }
              : null,
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
                    Expanded(child: selectbox()),
                    stopMessageButton(
                        desktopLandscapeWide: desktopLandscapeWide),
                    sendMessageButton(),
                  ],
                ),
              if (!desktopLandscapeWide) ...[
                selectbox(),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: EditableMultilineText(
                      label:
                          '${translations['messageNewLabel'] ?? 'New message'}:',
                      maxLines: 5,
                      height: 86.0,
                      textController: messageTextController,
                      onChanged: (String value) {
                        if (mounted) {
                          setState(() => messageTextController.text = value);
                        }
                      },
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.only(top: 3.0, right: 16.0, left: 4.0),
                    child: Column(
                      children: [
                        Ink(
                          decoration: ShapeDecoration(
                            color: messageTextController.text.isNotEmpty
                                ? Colors.blue
                                : Colors.grey,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4.0)),
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
                                    });
                                  }
                                }
                              }),
                        ),
                        const SizedBox(height: 5.0),
                        Ink(
                          decoration: ShapeDecoration(
                            color: selectedMessageId != null &&
                                    options.containsKey(selectedMessageId)
                                ? Colors.blue
                                : Colors.grey,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
                          child: IconButton(
                            color: Colors.white,
                            onPressed: () async {
                              if (selectedMessageId != null &&
                                  options.containsKey(selectedMessageId)) {
                                bool value = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                          builder: (context, setState) {
                                        return AlertDialog(
                                            title: Text(translations[
                                                    'dialogRemoveMessageQuestion'] ??
                                                'Do you really want to delete this message?'),
                                            actions: [
                                              ElevatedButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStateProperty
                                                            .resolveWith<Color>(
                                                      (Set<WidgetState>
                                                          states) {
                                                        return Colors.blueGrey;
                                                      },
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: Text(translations[
                                                          'dialogQuitNo'] ??
                                                      'No')),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 16.0),
                                                child: ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: Text(translations[
                                                            'dialogQuitYes'] ??
                                                        'Yes')),
                                              ),
                                            ]);
                                      });
                                    });
                                if (value == true) {
                                  setState(() {
                                    String key = selectedMessageId!;
                                    nameTextController.text = '';
                                    messageTextController.text = '';
                                    selectedMessageId = null;
                                    options.remove(key);
                                    mainBloc.setCustomMessages(
                                        messages: options);
                                  });
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.remove,
                              size: 20.0,
                            ),
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
