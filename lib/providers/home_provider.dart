import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helody/main.dart';
import 'package:helody/model/beatmap.dart';
import 'package:just_audio/just_audio.dart';

BeatmapModel beatmapNow = BeatmapModel();
BeatmapModel beatmapNowParent = BeatmapModel();

class HomeProvider extends ChangeNotifier {
  static late HomeProvider instance;

  get beatmap => beatmapNow;

  Future<void> recursionSubFile(String pathName, {bool isRoot = false}) async {
    Directory dir = Directory(pathName);

    if (!await dir.exists()) {
      return;
    }

    List<FileSystemEntity> lists = dir.listSync();
    for (FileSystemEntity entity in lists) {
      if (entity is File) {
        File file = entity;
        if (file.path.endsWith('.milthm')) {
          var fileData = await file.readAsString();
          BeatmapModel beatmapModel =
              BeatmapModel.fromJson(jsonDecode(fileData));
          beatmapModel.dirPath = pathName;
          beatmapModel.filePath = file.path;
          subList.add(beatmapModel);
        }
      } else if (entity is Directory) {
        Directory subDir = entity;
        await recursionSubFile(subDir.path);
      }
    }
    if (isRoot) {
      subList.sort((a, b) => (a.noteList.length).compareTo(b.noteList.length));
      notifyListeners();
    }
  }

  void selectBeatmap(BeatmapModel b, {isParent = false}) {
    if (beatmapNowParent == b) return;
    if (isParent) beatmapNowParent = b;
    beatmapNow = b;

    gamePlayer
      ?..setFilePath('${b.dirPath}/${b.audioFile ?? ''}')
      ..load().then((value) {
        gamePlayer
          ?..setLoopMode(LoopMode.one)
          ..seek(Duration(seconds: (b.previewTime ?? 0).round()))
          ..play();
      });
    subList.clear();
    recursionSubFile(b.dirPath, isRoot: true);
    // notifyListeners();
  }
}
