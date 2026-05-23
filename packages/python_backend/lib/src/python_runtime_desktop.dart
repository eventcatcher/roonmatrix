import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:serious_python/serious_python.dart';

Future<void> pythonRuntimeInit() async {
  if (!(Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    return;
  }

  String? response = await SeriousPython.run(
    'packages/python_backend/assets/backend/roonmatrix.zip',
    appFileName: 'roonmatrix.py',
    environmentVariables: {
      "embedded": "true",
      "platform": Platform.operatingSystem,
    },
  );
  if (kDebugMode) {
    debugPrint(
      'virtual device started${response != null && response.isNotEmpty ? ' (response: $response)' : ''}',
    );
  }
}
