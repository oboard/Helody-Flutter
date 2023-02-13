import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> getGamePath() async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  return '$appDocPath/milthm';
}
