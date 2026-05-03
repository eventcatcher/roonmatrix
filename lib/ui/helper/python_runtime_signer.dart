import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PythonRuntimeSigner {
  static Future<String> runtimePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'flet', 'assets', 'backend');
  }

  static Future<void> prepare() async {
    final runtimeDir = await runtimePath();

    if (!await Directory(runtimeDir).exists()) {
      return;
    }

    // Quarantäne entfernen
    await Process.run('xattr', ['-dr', 'com.apple.quarantine', runtimeDir]);

    // Alle nativen Bibliotheken signieren
    await _signNativeFiles(runtimeDir);

    // Abschließend Hauptordner signieren
    await Process.run('codesign', [
      '--force',
      '--deep',
      '--sign',
      '-',
      runtimeDir,
    ]);
  }

  static Future<void> _signNativeFiles(String root) async {
    await for (final entity in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final path = entity.path.toLowerCase();

      final shouldSign =
          path.endsWith('.so') ||
          path.endsWith('.dylib') ||
          await _isExecutable(entity);

      if (!shouldSign) continue;

      if (kDebugMode) {
        debugPrint('PythonRuntimeSigner codesign ${entity.path}');
      }

      final result = await Process.run('codesign', [
        '--force',
        '--timestamp=none',
        '--sign',
        '-',
        entity.path,
      ]);

      if (result.exitCode != 0) {
        stderr.writeln(
          'PythonRuntimeSigner Codesign fehlgeschlagen: ${entity.path}\n${result.stderr}',
        );
      }
    }
  }

  static Future<bool> _isExecutable(File file) async {
    final result = await Process.run('test', ['-x', file.path]);
    return result.exitCode == 0;
  }
}
