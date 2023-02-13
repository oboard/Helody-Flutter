import 'dart:convert';
import 'dart:io';

import 'package:helody/utils/luid_util.dart';
import 'dart:math' as math;

class BPMData {
  double start = 0;
  double bpm = 60;

  BPMData({this.start = 0, this.bpm = 60});

  BPMData.fromJson(Map<String, dynamic>? json) {
    bpm = json?['BPM'];
    start = json?['Start'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['BPM'] = bpm;
    data['Start'] = start;
    return data;
  }
}

class NoteData {
  int line = 0;
  List<int> from = [], to = [];
  int bpm = 60;
  String snd = '';

  bool judged = false;

  NoteData({
    this.line = 0,
    this.from = const [],
    this.to = const [],
    this.bpm = 60,
    this.snd = '',
  });

  double get fromBeat {
    return from[0] + from[1] * 1.0 / from[2];
  }

  double get toBeat {
    return to[0] + to[1] * 1.0 / to[2];
  }

  NoteData.fromJson(Map<String, dynamic>? json) {
    line = json?['Line'];
    bpm = json?['BPM'];
    snd = json?['Snd'];
    json?['From'].forEach((v) {
      from.add(v);
    });
    json?['To'].forEach((v) {
      to.add(v);
    });
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Line'] = line;
    data['BPM'] = bpm;
    data['Snd'] = snd;
    data['From'] = from;
    data['To'] = to;
    return data;
  }
}

enum LineDirection {
  left,
  right,
  up,
  down,
}

class LineData {
  LineDirection? direction;
  double? flowSpeed;
  LineData(this.direction, this.flowSpeed);
  LineData.fromJson(Map<String, dynamic>? json) {
    direction = [
      LineDirection.left,
      LineDirection.right,
      LineDirection.up,
      LineDirection.down
    ][json?['Direction']];
    flowSpeed = json?['FlowSpeed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Direction'] = {
      LineDirection.left: 0,
      LineDirection.right: 1,
      LineDirection.up: 2,
      LineDirection.down: 3
    }[direction];
    data['FlowSpeed'] = flowSpeed;
    return data;
  }
}

enum PerformanceOperation {
  move,
  rotate,
  transparent,
  changeDirection,
  changeKey,
  flowSpeed,
}

enum PerformanceEaseType {
  linear,
  bezierEaseIn,
  bezierEaseOut,
  bezierEase,
  parabolicEase,
}

class PerformanceData {
  double? from, to;
  int? line, note;
  PerformanceOperation? operation;
  String? value;
  PerformanceEaseType? ease;
}

class BeatmapModel {
  String? title;
  String? composer;
  String? illustrator;
  String? beatmapper;
  String? beatmapUID = Luid().v1();
  String? difficulty;
  double? difficultyValue;
  String? audioFile;
  String? illustrationFile;
  String? source;
  String? gameSource;
  double? previewTime = -1;
  double? songLength = 0;
  double songOffset = 0;
  String formatVersion = '';
  String sndSet = '';

  String filePath = '';
  String dirPath = '';

  List<BPMData> bpmList = [];

  List<NoteData> noteList = [];

  List<LineData> lineList = [];

  List<PerformanceData> performanceList = <PerformanceData>[];

  BeatmapModel({
    this.title,
    this.composer,
    this.illustrator,
    this.beatmapper,
    this.beatmapUID,
    this.difficulty,
    this.difficultyValue,
    this.audioFile,
    this.illustrationFile,
    this.source,
    this.gameSource,
    this.previewTime,
    this.songLength,
    this.songOffset = 0,
    this.formatVersion = '',
    this.sndSet = '',
  });

  Future<void> export(String filePath) async {
    File file = File(filePath);
    print(filePath);
    await file.writeAsString(jsonEncode(toJson()));
  }

  double determineBPM(double time) {
    if (bpmList.length == 1) {
      return 0;
    } else {
      double ret = 0;
      for (int i = 0; i < bpmList.length; i++) {
        if (time < bpmList[i].start) {
          break;
        } else {
          ret = bpmList[i].bpm;
        }
      }
      return ret;
    }
  }

  List<int> convertByBPM(double time, int beat, {double bpm = -1}) {
    if (bpm == -1) {
      bpm = determineBPM(time);
    }
    BPMData bpmData = bpmList.where((e) => e.bpm == bpm).toList()[0];
    double beattime = 60.0 / bpmData.bpm;
    int basebeat = (time - bpmData.start) ~/ beattime;
    return [
      basebeat,
      ((time - bpmData.start - basebeat * beattime) / (beattime / beat))
          .round(),
      beat
    ];
  }

  List<double> toRealTime(NoteData note) {
    return [
      bpmList[note.bpm].start + note.fromBeat * (60.0 / bpmList[note.bpm].bpm),
      bpmList[note.bpm].start + note.toBeat * (60.0 / bpmList[note.bpm].bpm)
    ];
  }

  static BeatmapModel read(String path) {
    return BeatmapModel.fromJson(jsonDecode(File(path).readAsStringSync()));
  }

  double bezierCubic(double t, double a, double b, double c, double d) {
    return (a * math.pow(1 - t, 3)) +
        (3 * b * t * math.pow(1 - t, 2)) +
        (3 * c * (1 - t) * math.pow(t, 2)) +
        (d * math.pow(t, 3));
  }

  BeatmapModel.fromJson(Map<String, dynamic>? json) {
    title = json?['Title'];
    composer = json?['Composer'];
    illustrator = json?['Illustrator'];
    beatmapper = json?['Beatmapper'];
    beatmapUID = json?['BeatmapUID'];
    difficulty = json?['Difficulty'];
    difficultyValue = json?['DifficultyValue'];
    audioFile = json?['AudioFile'];
    illustrationFile = json?['IllustrationFile'];
    source = json?['Source'];
    gameSource = json?['GameSource'];
    previewTime = json?['PreviewTime'];
    songLength = json?['SongLength'];
    songOffset = json?['SongOffset'];
    formatVersion = json?['FormatVersion'];
    sndSet = json?['SndSet'];

    json?['BPMList'].forEach((v) {
      bpmList.add(BPMData.fromJson(v));
    });
    json?['NoteList'].forEach((v) {
      noteList.add(NoteData.fromJson(v));
    });
    json?['LineList'].forEach((v) {
      lineList.add(LineData.fromJson(v));
    });
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Title'] = title;
    data['Composer'] = composer;
    data['Illustrator'] = illustrator;
    data['Beatmapper'] = beatmapper;
    data['BeatmapUID'] = beatmapUID;
    data['Difficulty'] = difficulty;
    data['DifficultyValue'] = difficultyValue;
    data['AudioFile'] = audioFile;
    data['IllustrationFile'] = illustrationFile;
    data['Source'] = source;
    data['GameSource'] = gameSource;
    data['PreviewTime'] = previewTime;
    data['SongLength'] = songLength;
    data['SongOffset'] = songOffset;
    data['FormatVersion'] = formatVersion;
    data['SndSet'] = sndSet;
    data['BPMList'] = bpmList.map((v) => v.toJson()).toList();
    data['NoteList'] = noteList.map((v) => v.toJson()).toList();
    data['LineList'] = lineList.map((v) => v.toJson()).toList();
    return data;
  }
}
