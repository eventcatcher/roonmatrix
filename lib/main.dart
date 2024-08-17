import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:flutter/foundation.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';
import 'package:roonmatrix/ui/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await _configureMacosWindowUtils();

  if (Platform.isIOS) {
    DartPingIOS.register();
  }

  final appDocDirectory = await getApplicationDocumentsDirectory();
  try {
    configureNetworkTools(appDocDirectory.path, enableDebugging: false);
  } catch (e) {
    if (kDebugMode) {
      print('configureNetworkTools error: $e');
    }
  }

  runApp(const RoonMatrix());

  Bloc.transformer = sequential<
      dynamic>(); // all bloc events strictly sequential (like mapEventToState in bloc prior v8)

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    doWhenWindowReady(() {
      const initialSize = Size(1152, 768);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;

      //appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }
}

class RoonMatrix extends StatefulWidget {
  const RoonMatrix({super.key});

  @override
  State<RoonMatrix> createState() => RoonMatrixState();
}

class RoonMatrixState extends State<RoonMatrix> {
  final bool showOptions = false;
  final FileRepository fileRepository = FileRepository();

  Options options = Options((OptionsBuilder b) => b..polling = true);
  bool saveIdle = false;

  late OptionsBloc optionsBloc;

  @override
  void initState() {
    fileRepository.init();
    optionsBloc = OptionsBloc(fileRepository: fileRepository);
    optionsBloc.loadOptions(options);
    super.initState();
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OptionsBloc>(
          create: (BuildContext context) => optionsBloc,
        ),
      ],
      child: MaterialApp(
        title: 'RoonMatrix',
        theme: ThemeData.light(
            useMaterial3: false), // ThemeData(primarySwatch: Colors.blue),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light, // system
        home: BlocBuilder(
            bloc: optionsBloc,
            builder: (context, OptionsState optionsState) {
              if (optionsState is OptionsStateLoaded) {
                options = optionsState.options ?? options;
              }
              return Platform.isMacOS
                  ? PlatformMenuBar(
                      menus: <PlatformMenuItem>[
                        PlatformMenu(
                          label: 'roonmatrix',
                          menus: <PlatformMenuItem>[
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType.about))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType.about),
                              ],
                            ),
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType
                                        .servicesSubmenu))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .servicesSubmenu),
                              ],
                            ),
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType.hide))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType.hide),
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType
                                        .hideOtherApplications))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .hideOtherApplications),
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType
                                        .showAllApplications))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .showAllApplications),
                              ],
                            ),
                            PlatformMenuItemGroup(members: <PlatformMenuItem>[
                              if (PlatformProvidedMenuItem.hasMenu(
                                  PlatformProvidedMenuItemType.quit))
                                const PlatformProvidedMenuItem(
                                    type: PlatformProvidedMenuItemType.quit),
                            ]),
                          ],
                        ),
                        PlatformMenu(
                          label: 'File',
                          menus: <PlatformMenuItem>[
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                PlatformMenuItem(
                                  label: 'Export Device Data',
                                  shortcut: const SingleActivator(
                                      LogicalKeyboardKey.keyD,
                                      meta: true),
                                  onSelected: () async {
                                    setState(() {
                                      saveIdle = true;
                                    });
                                    bool? valid =
                                        await optionsBloc.exportDevicesData();
                                    setState(() {
                                      saveIdle = false;
                                    });
                                    if (valid == null) {
                                      return;
                                    }
                                    if (valid == true) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text("export successfully done"),
                                          backgroundColor: Colors.green,
                                        ));
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text("export failed!"),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    }
                                  },
                                ),
                                // PlatformMenuItem(
                                //   label: 'Searching',
                                //   shortcut: const SingleActivator(
                                //       LogicalKeyboardKey.keyL,
                                //       meta: true),
                                //   onSelected: () {
                                //     optionsBloc.searching();
                                //   },
                                // ),
                              ],
                            ),
                          ],
                        ),
                        PlatformMenu(
                          label: 'Edit',
                          menus: <PlatformMenuItem>[
                            const PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                PlatformMenuItem(
                                  label: 'Undo',
                                  shortcut: SingleActivator(
                                      LogicalKeyboardKey.keyZ,
                                      meta: true),
                                ),
                                PlatformMenuItem(
                                  label: 'Redo',
                                  shortcut: SingleActivator(
                                      LogicalKeyboardKey.keyZ,
                                      meta: true,
                                      shift: true),
                                ),
                              ],
                            ),
                            const PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                PlatformMenuItem(
                                  label: 'Cut',
                                  shortcut: SingleActivator(
                                      LogicalKeyboardKey.keyX,
                                      meta: true),
                                ),
                                PlatformMenuItem(
                                  label: 'Copy',
                                  shortcut: SingleActivator(
                                      LogicalKeyboardKey.keyC,
                                      meta: true),
                                ),
                                PlatformMenuItem(
                                  label: 'Paste',
                                  shortcut: SingleActivator(
                                      LogicalKeyboardKey.keyV,
                                      meta: true),
                                ),
                                PlatformMenuItem(
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            const PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                PlatformMenuItem(
                                  label: 'Select All',
                                  shortcut: SingleActivator(
                                      LogicalKeyboardKey.keyA,
                                      meta: true),
                                ),
                              ],
                            ),
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                PlatformMenu(
                                  label: 'Speach',
                                  menus: <PlatformMenuItem>[
                                    PlatformMenuItemGroup(
                                      members: <PlatformMenuItem>[
                                        if (PlatformProvidedMenuItem.hasMenu(
                                            PlatformProvidedMenuItemType
                                                .startSpeaking))
                                          const PlatformProvidedMenuItem(
                                              type: PlatformProvidedMenuItemType
                                                  .startSpeaking),
                                        if (PlatformProvidedMenuItem.hasMenu(
                                            PlatformProvidedMenuItemType
                                                .stopSpeaking))
                                          const PlatformProvidedMenuItem(
                                              type: PlatformProvidedMenuItemType
                                                  .stopSpeaking),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        PlatformMenu(
                          label: 'View',
                          menus: <PlatformMenuItem>[
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType
                                        .toggleFullScreen))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .toggleFullScreen),
                              ],
                            ),
                          ],
                        ),
                        if (showOptions == true)
                          PlatformMenu(
                            label: 'Options',
                            menus: <PlatformMenuItem>[
                              PlatformMenuItemGroup(
                                members: <PlatformMenuItem>[
                                  PlatformMenuItem(
                                      label:
                                          '${options.polling ? '\u2713 ' : '    '}polling',
                                      shortcut: const SingleActivator(
                                          LogicalKeyboardKey.keyP,
                                          meta: true,
                                          alt: true),
                                      onSelected: () {
                                        optionsBloc.setOptionsPolling(
                                            polling: !options.polling);
                                      }),
                                  PlatformMenuItem(
                                      label: '    Reset Options',
                                      shortcut: const SingleActivator(
                                          LogicalKeyboardKey.keyR,
                                          meta: true,
                                          alt: true),
                                      onSelected: () {
                                        optionsBloc.resetOptions();
                                      }),
                                ],
                              ),
                            ],
                          ),
                        PlatformMenu(
                          label: 'Window',
                          menus: <PlatformMenuItem>[
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType
                                        .minimizeWindow))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .minimizeWindow),
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType.zoomWindow))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .zoomWindow),
                              ],
                            ),
                            PlatformMenuItemGroup(
                              members: <PlatformMenuItem>[
                                if (PlatformProvidedMenuItem.hasMenu(
                                    PlatformProvidedMenuItemType
                                        .arrangeWindowsInFront))
                                  const PlatformProvidedMenuItem(
                                      type: PlatformProvidedMenuItemType
                                          .arrangeWindowsInFront),
                              ],
                            ),
                          ],
                        ),
                      ],
                      child: StartPage(
                          title: 'RoonMatrix',
                          showOptions: showOptions,
                          options: options),
                    )
                  : StartPage(
                      title: 'RoonMatrix',
                      showOptions: showOptions,
                      options: options);
            }),
      ),
    );
  }
}
