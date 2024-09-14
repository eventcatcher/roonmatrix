import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await _configureMacosWindowUtils();

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
  late SettingsBloc settingsBloc;
  late String appVersionAndBuildNumber;

  @override
  void initState() {
    getAppVersionAndBuildNumber();
    fileRepository.init();
    settingsBloc = SettingsBloc();
    optionsBloc = OptionsBloc(fileRepository: fileRepository);
    optionsBloc.loadOptions(options);
    super.initState();
  }

  Future<void> getAppVersionAndBuildNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersionAndBuildNumber =
        '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  void openAboutModal(BuildContext context) async => ApproveModal(
        context: context,
        icon: Container(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SizedBox(
            width: 64,
            height: 64,
            child: SvgPicture.asset(
              'assets/svg/8-8-led-matrix-display-unit.svg',
              allowDrawingOutsideViewBox: false,
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
            ),
          ),
        ),
        title: "roonmatrix",
        question:
            "Version $appVersionAndBuildNumber\n\nCopyright © 2024 de.eventcatcher. All rights reserved.",
        okText: 'OK',
        cancelText: '',
        onApproved: () {
          //
        },
      ).show();

  List<BarButton> menuBarButtons(BuildContext context) {
    return [
      BarButton(
        text: const Text(
          'File',
          style: TextStyle(color: Colors.white),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () => showGeneralDialog(
                context: context,
                barrierColor:
                    Colors.black12.withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, __, ___) {
                  return SettingsPage(
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              shortcutText: 'Ctrl+,',
              shortcut: const SingleActivator(LogicalKeyboardKey.comma,
                  control: true),
              text: const Text('Settings'),
              icon: const Icon(Icons.settings),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () => FlutterWindowClose.closeWindow(),
              shortcut:
                  const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
              shortcutText: 'Ctrl+Q',
              text: const Text('Quit'),
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
      ),
      BarButton(
        text: const Text(
          'Help',
          style: TextStyle(color: Colors.white),
        ),
        submenu: SubMenu(
          menuItems: [
            // MenuButton(
            //   onTap: () {},
            //   shortcut:
            //       const SingleActivator(LogicalKeyboardKey.keyU, control: true),
            //   shortcutText: 'Ctrl+U',
            //   text: const Text('Check for updates'),
            // ),
            // const MenuDivider(),
            MenuButton(
              onTap: () => openAboutModal(context),
              icon: const Icon(Icons.info),
              text: const Text('About'),
            ),
          ],
        ),
      ),
    ];
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (BuildContext context) => settingsBloc,
        ),
        BlocProvider<OptionsBloc>(
          create: (BuildContext context) => optionsBloc,
        ),
      ],
      child: MaterialApp(
        title: 'RoonMatrix',
        theme: ThemeData(
          useMaterial3: false,
          tabBarTheme: const TabBarTheme(
              labelColor: Colors.white,
              dividerColor: Colors.grey,
              //overlayColor: WidgetStatePropertyAll(Colors.purple),
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: Colors.red))),
        ),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light, // system
        home: BlocBuilder(
            bloc: optionsBloc,
            builder: (context, OptionsState optionsState) {
              if (optionsState is OptionsStateLoaded) {
                options = optionsState.options ?? options;
              }
              if (Platform.isMacOS) {
                return PlatformMenuBar(
                  menus: <PlatformMenuItem>[
                    PlatformMenu(
                      label: 'RoonMatrix',
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
                            PlatformMenuItem(
                              label: 'Settings',
                              shortcut: const SingleActivator(
                                  LogicalKeyboardKey.comma,
                                  meta: true),
                              onSelected: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierColor: Colors.black12
                                      .withOpacity(0.6), // Background color
                                  barrierDismissible: false,
                                  barrierLabel: 'Dialog',
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                  pageBuilder: (_, __, ___) {
                                    return SettingsPage(
                                      close: () {
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        PlatformMenuItemGroup(
                          members: <PlatformMenuItem>[
                            if (PlatformProvidedMenuItem.hasMenu(
                                PlatformProvidedMenuItemType.servicesSubmenu))
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
                                      content: Text("export successfully done"),
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
                            //     optionsBloc.searching(idle:true);
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
                              shortcut: SingleActivator(LogicalKeyboardKey.keyZ,
                                  meta: true),
                            ),
                            PlatformMenuItem(
                              label: 'Redo',
                              shortcut: SingleActivator(LogicalKeyboardKey.keyZ,
                                  meta: true, shift: true),
                            ),
                          ],
                        ),
                        const PlatformMenuItemGroup(
                          members: <PlatformMenuItem>[
                            PlatformMenuItem(
                              label: 'Cut',
                              shortcut: SingleActivator(LogicalKeyboardKey.keyX,
                                  meta: true),
                            ),
                            PlatformMenuItem(
                              label: 'Copy',
                              shortcut: SingleActivator(LogicalKeyboardKey.keyC,
                                  meta: true),
                            ),
                            PlatformMenuItem(
                              label: 'Paste',
                              shortcut: SingleActivator(LogicalKeyboardKey.keyV,
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
                              shortcut: SingleActivator(LogicalKeyboardKey.keyA,
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
                                PlatformProvidedMenuItemType.toggleFullScreen))
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
                                PlatformProvidedMenuItemType.minimizeWindow))
                              const PlatformProvidedMenuItem(
                                  type: PlatformProvidedMenuItemType
                                      .minimizeWindow),
                            if (PlatformProvidedMenuItem.hasMenu(
                                PlatformProvidedMenuItemType.zoomWindow))
                              const PlatformProvidedMenuItem(
                                  type:
                                      PlatformProvidedMenuItemType.zoomWindow),
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
                );
              }
              if (Platform.isWindows || Platform.isLinux) {
                return MenuBarWidget(
                  // Add a list of [BarButton]. The buttons in this List are
                  // displayed as the buttons on the bar itself
                  barButtons: menuBarButtons(context),

                  // Style the menu bar itself. Hover over [MenuStyle] for all the options
                  barStyle: const MenuStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    backgroundColor: WidgetStatePropertyAll(Color(0xFF2b2b2b)),
                    maximumSize:
                        WidgetStatePropertyAll(Size(double.infinity, 28.0)),
                  ),

                  // Style the menu bar buttons. Hover over [ButtonStyle] for all the options
                  barButtonStyle: const ButtonStyle(
                    padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 6.0)),
                    minimumSize: WidgetStatePropertyAll(Size(0.0, 32.0)),
                  ),

                  // Style the menu and submenu buttons. Hover over [ButtonStyle] for all the options
                  menuButtonStyle: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size.fromHeight(36.0)),
                    padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0)),
                  ),

                  // Enable or disable the bar
                  enabled: true,

                  // Set the child, i.e. the application under the menu bar
                  child: StartPage(
                      title: 'RoonMatrix',
                      showOptions: showOptions,
                      options: options),
                );
              }

              return StartPage(
                  title: 'RoonMatrix',
                  showOptions: showOptions,
                  options: options);
            }),
      ),
    );
  }
}
