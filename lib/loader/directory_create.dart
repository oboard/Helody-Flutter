import 'dart:io';

import 'path.dart';

Future<void> checkAndCreateImportDictory() async {
  String appDocPath = await getGamePath();
  if (!Directory(appDocPath).existsSync()) {
    await Directory(appDocPath).create();
  }
  if (!Directory('$appDocPath/imports').existsSync()) {
    await Directory('$appDocPath/imports').create();
  }
}
