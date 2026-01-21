import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
      debugPrint(
        'AppLifecyclePageWrapper/didUpdateWidget',
      );
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

    if (state == AppLifecycleState.resumed) {
      widget.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
