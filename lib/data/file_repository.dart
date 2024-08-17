import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roonmatrix/data/storage_folder_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileRepository {
  final bool saveDownloadsInPublicStorage = true;
  final Directory generalAndroidDownloadDir =
      Directory('/storage/emulated/0/Download');

  bool accessIsGranted = true;
  String myLocalPath = '';

  late SharedPreferences prefs;

  FileRepository();

  String get localPath {
    return myLocalPath;
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    if (saveDownloadsInPublicStorage == true) {
      accessIsGranted = await downloadFolderPermissionRequest();
    }
    myLocalPath = await fetchLocalPath();
  }

  Future<File> read(
      {required String fileName, required String subFolder}) async {
    return await _localFile(fileName, subFolder);
  }

  Future<File> write(
      {required String subFolder,
      required String fileName,
      required Uint8List bytes}) async {
    final path = await _localPath(subFolder);
    Future<File> file =
        File('$path/$fileName').create(recursive: true).then((File file) {
      return file.writeAsBytes(bytes);
    });

    return file;
  }

  Future<bool> downloadFolderPermissionRequest() async {
    bool accessIsGranted = true;

    if (saveDownloadsInPublicStorage) {
      PermissionStatus status = await Permission.storage.status;
      if (status == PermissionStatus.granted ||
          await Permission.storage.request().isGranted) {
        accessIsGranted = true;
      }
    }

    if (!accessIsGranted) {
      log('[FileRepository] downloadFolderPermissionRequest/error -> file access not allowed');
    }

    return accessIsGranted;
  }

  Future<String> fetchLocalPath() async {
    Directory? publicDir = generalAndroidDownloadDir;
    if (Platform.isAndroid) {
      publicDir = generalAndroidDownloadDir;
    } else if (Platform.isIOS) {
      publicDir = await getApplicationDocumentsDirectory();
    } else {
      publicDir = await getExternalStorageDirectory();
    }

    if (!kIsWeb && publicDir != null) {
      final Directory directory = saveDownloadsInPublicStorage
          ? publicDir
          : await getApplicationDocumentsDirectory();
      return directory.path;
    }
    return './';
  }

  Future<File> _localFile(String fileName, String subFolder) async {
    final path = await _localPath(subFolder);
    return File('$path/$fileName');
  }

  Future<String> _localPath(String subFolder) async {
    Directory? publicDir = generalAndroidDownloadDir;
    if (Platform.isAndroid) {
      publicDir = generalAndroidDownloadDir;
    } else if (Platform.isIOS) {
      publicDir = await getApplicationDocumentsDirectory();
    } else {
      publicDir = await getExternalStorageDirectory();
    }

    if (!kIsWeb && publicDir != null) {
      final Directory directory = saveDownloadsInPublicStorage == true
          ? publicDir
          : await getApplicationDocumentsDirectory();

      return "${directory.path}$subFolder";
    }

    return "./$subFolder";
  }

  Future<void> removeAllLocalFiles() async {
    final Directory dir = Directory(localPath);
    List<FileSystemEntity> list = dir.listSync();
    // ignore:avoid_function_literals_in_foreach_calls
    list.forEach((FileSystemEntity f) => f.deleteSync(recursive: true));
  }

  bool isFileExist({required String localFileName}) {
    bool existinLocalPath = File("$localPath/$localFileName").existsSync();

    return existinLocalPath;
  }

  int getFileSize({required String localFileName}) {
    int length = -1;

    bool existinLocalPath = File("$localPath/$localFileName").existsSync();
    if (existinLocalPath) {
      length = File("$localPath/$localFileName").lengthSync();
    }

    return length;
  }

  List<Permission> getListOfPermissionsWeNeed(
      {required StorageFolderType storageFolderType}) {
    List<Permission> permissions = [];

    if (storageFolderType == StorageFolderType.EXTERNAL) {
      permissions.add(Permission.storage);

      if (Platform.isAndroid) {
        permissions.add(Permission.manageExternalStorage);
        permissions.add(Permission.requestInstallPackages);
      }
    }

    return permissions;
  }

  Future<List<Permission>> getListOfPermissionsToRequest(
      {required List<Permission> permissions}) async {
    List<Permission> permissionsToRequst = [];

    for (Permission permission in permissions) {
      PermissionStatus permissionStatus = await permission.status;
      if (permissionStatus.isGranted == false &&
          permissionStatus != PermissionStatus.granted) {
        permissionsToRequst.add(permission);
      }
    }

    return permissionsToRequst;
  }

  Future<Map<Permission, PermissionStatus>> permissionsRequest(
      {required List<Permission> permissions}) async {
    Map<Permission, PermissionStatus> statusMap = await permissions.request();
    statusMap.removeWhere((key, value) => value.isGranted);
    if (statusMap.isNotEmpty) {
      log("permissionsRequest not granted error => statusMap: ${statusMap.toString()}");
    }

    return statusMap;
  }

  Future<bool> setStopAskingForPermissions() async {
    return prefs.setString('stopAskingForPermissions',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
  }

  Future<bool> removeStopAskingForPermissions() async {
    return prefs.remove('stopAskingForPermissions');
  }

  bool isStopAskingForPermissions() =>
      prefs.containsKey('stopAskingForPermissions');

  Future<File?> saveFileFromUrl(
      {required String url,
      required String subFolder,
      required String fileName,
      StorageFolderType storageFolderType = StorageFolderType.APP}) async {
    try {
      Directory? directory;
      File? saveFile;
      Map<Permission, PermissionStatus> statusMap = {};
      bool pG = true;

      List<Permission> permissions =
          getListOfPermissionsWeNeed(storageFolderType: storageFolderType);
      List<Permission> permissionsToRequest =
          await getListOfPermissionsToRequest(permissions: permissions);
      if (permissionsToRequest.isNotEmpty) {
        statusMap = await permissionsRequest(permissions: permissionsToRequest);
        statusMap.removeWhere((key, value) => value.isGranted);
        pG = statusMap.isEmpty;
      }

      if (pG) {
        if (storageFolderType == StorageFolderType.EXTERNAL) {
          // if a download is interrupted, next try to download results in: OS Error: No such file or directory, errno = 2
          // you need to wait a minute and try again. it should solve the problem.
          directory = Platform.isIOS
              ? await getTemporaryDirectory()
              : await getExternalStorageDirectory();

          // ignore:prefer_conditional_assignment
          if (directory == null) {
            directory = await getTemporaryDirectory();
          }
        } else if (storageFolderType == StorageFolderType.TEMP) {
          directory = await getTemporaryDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        String newPath = '';
        List<String> paths = directory.path.split('/');
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != 'Android') {
            newPath += '/$folder';
          } else {
            break;
          }
        }
        newPath += subFolder;

        directory = Directory(newPath);
        log('FileRepository/saveFile, path: ${directory.path}/$fileName');

        saveFile = File('${directory.path}/$fileName');
        if (saveFile.existsSync()) {
          saveFile.deleteSync();
          log('FileRepository/saveFile, existing file deleted');
        }
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await Dio().download(
          url,
          saveFile.path,
        );
      } else {
        log('permissions not granted error (url: $url, subFolder: $subFolder, fileName: $fileName, statusMap: ${statusMap.toString()})',
            name: 'FileRepository/saveFile/error');
      }

      return saveFile;
    } catch (e) {
      log('url: $url, subFolder: $subFolder, fileName: $fileName, error: ${e.toString()}',
          name: 'FileRepository/saveFile/catch');
      return Future.value(null);
    }
  }
}
