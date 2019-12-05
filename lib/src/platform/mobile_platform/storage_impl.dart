import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:working_pacemaker/src/platform/platform.dart';

class StorageImpl implements Storage {
  static const _fileExtension = 'json';

  Future<String> get(String key, {String namespace}) async {
    final file = await getFile(key, namespace: namespace);

    if (await file.exists()) {
      return file.readAsString();
    } else {
      return null;
    }
  }

  Future<bool> exists(String key, {String namespace}) async {
    final file = await getFile(key, namespace: namespace);
    return file.exists();
  }

  Future<bool> set(String key, String value, {String namespace}) async {
    try {
      var file = await getFile(key, namespace: namespace);

      if (!await file.exists()) {
        file = await file.create(recursive: true);
      }
      await file.writeAsString(value);
      return true;
    } catch (error, trace) {
      print(error);
      print(trace);
      return false;
    }
  }

  Future<List<String>> listKeys({String namespace}) async {
    final directory =
        await getDirectoryPath(namespace).then((path) => Directory(path));

    if (!(await directory.exists())) {
      return [];
    }

    return directory
        .list()
        .map((e) => path.basenameWithoutExtension(e.path))
        .toList();
  }

  Future<bool> delete(String key, {String namespace}) async {
    try {
      final file = await getFile(key, namespace: namespace);
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @protected
  Future<File> getFile(String key, {String namespace}) async {
    final dirPath = await getDirectoryPath(namespace);
    final basename = '$key.$_fileExtension';
    return File(path.join(dirPath, basename));
  }

  @protected
  Future<String> getDirectoryPath(String namespace) async {
    final applicationDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    return namespace != null
        ? path.join(applicationDocumentsDirectory.path, namespace)
        : applicationDocumentsDirectory.path;
  }
}
