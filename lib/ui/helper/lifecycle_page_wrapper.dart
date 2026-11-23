import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';

class AppLifecyclePageWrapper extends StatefulWidget {
  final VoidCallback onResume;
  final Widget child;

  const AppLifecyclePageWrapper({
    super.key,
    required this.onResume,
    required this.child,
  });

  @override
  State<AppLifecyclePageWrapper> createState() =>
      _AppLifecyclePageWrapperState();
}

class _AppLifecyclePageWrapperState extends State<AppLifecyclePageWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(AppLifecyclePageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode) {
      debugPrint('AppLifecyclePageWrapper/didUpdateWidget');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint(
        'AppLifecyclePageWrapper/didChangeAppLifecycleState =>  => change to $state',
      );
    }

    if (state == AppLifecycleState.resumed && Globals.isMobileDevice()) {
      // init things (on desktop by switch from AppLifecycleState.inactive to resumed, it reloads info data => rebuild config page and scrolling to top, so config editing will be disturbed)
      // as example: if you switch to another app like Roon to do things like 'play next', the appcycle will change to inactive
      // if you switch then back to the roonmatrix app, the appcycle will change to resumed
      // in this case you lost the editing position on the config page if its opened, or the monitoring page will automatically scroll to top.
      // so, the onResume will only be called on mobile platforms.
      widget.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
