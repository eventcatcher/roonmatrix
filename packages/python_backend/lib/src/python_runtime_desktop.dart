import 'package:flutter/foundation.dart';
import 'package:serious_python/serious_python.dart';
import 'package:path_provider/path_provider.dart';

Future<void> pythonRuntimeInit() async {
  debugPrint('pythonRuntimeInit START');
  // if (!(Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
  //   return;
  // }

  final dir = await getApplicationSupportDirectory();

  String? response = await SeriousPython.run(
    'packages/python_backend/assets/backend/roonmatrix.zip',
    appFileName: 'roonmatrix.py',
    environmentVariables: {
      "embedded": "true",
      "platform": "ios", // Platform.operatingSystem,
      "configs_dir": dir.path,
    },
  );

  debugPrint(
    'virtual device started${response != null && response.isNotEmpty ? ' (response: $response)' : ''}',
  );
  debugPrint('pythonRuntimeInit END');
}
