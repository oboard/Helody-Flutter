import 'dart:io';

import 'package:helody/model/beatmap.dart';

import '../setting.dart';

class OsuManiaConverter {
  static Future<bool> convert(String path, String filePath,
      {double flowSpeed = 9.0}) async {
    File file = File(filePath);
    List<String> data = file.readAsStringSync().split(RegExp(r'\n|\r'));
    bool start = false;

    BeatmapModel model = BeatmapModel()
      ..difficultyValue = -1
      ..illustrator = "Unknown"
      ..gameSource = "Osu!Mania"
      ..songLength = -1
      ..formatVersion = GameSettings.formatVersion;

    bool readBg = false;
    int lineCount = 4;
    for (String line in data) {
      if (line == "[HitObjects]") {
        break;
      }
      if (line.startsWith("SampleSet: ")) {
        String set = line.split(':')[1].trim().toLowerCase();
        if (set == "drum") {
          model.sndSet = "osu-drum";
        } else if (set == "soft") {
          model.sndSet = "osu-soft";
        } else if (set == "normal") {
          model.sndSet = "osu-normal";
        }
      }

      if (line.startsWith("TitleUnicode:")) {
        model.title = line.split(':')[1];
      }

      if (line.startsWith("ArtistUnicode:")) {
        model.composer = line.split(':')[1];
      }

      if (line.startsWith("Creator:")) {
        model.beatmapper = line.split(':')[1];
      }

      if (line.startsWith("Source:")) {
        model.source = line.split(':')[1];
      }

      if (line.startsWith("Version:")) {
        model.difficulty = line.split(':')[1];
      }

      if (line.startsWith("AudioFilename:")) {
        model.audioFile = line.split(':')[1].trim();
      }

      if (line.startsWith("BeatmapID:")) {
        model.beatmapUID = "Osu!Mania-${line.split(':')[1]}";
      }

      if (line.startsWith("PreviewTime:")) {
        model.previewTime =
            (int.tryParse(line.split(':')[1].trim()) ?? 1) / 1000;
      }

      if (line.startsWith("CircleSize")) {
        lineCount = int.tryParse(line.split(':')[1].trim()) ?? 0;
      }

      if (line == "[Events]") {
        readBg = true;
        continue;
      }
      if (line.startsWith("[") && readBg) {
        readBg = false;
        continue;
      }

      if (!line.startsWith("//") &&
          readBg &&
          !line.startsWith("Video") &&
          line.isNotEmpty) {
        readBg = false;
        model.illustrationFile = line.split('"')[1];
      }

      if (line.startsWith("Mode:")) {
        if (line.split(':')[1].trim() != "3") {
          continue;
        }
      }
    }

    double lstBPM = 0;
    bool timingpoint = false;
    for (String line in data) {
      if (line.startsWith("[") && timingpoint) {
        break;
      }
      if (line == "[TimingPoints]") {
        timingpoint = true;
      }
      if (timingpoint) {
        // 1019,480,4,2,1,100,1,0
        List<String> t = line.split(',');
        if (t.length > 2) {
          BPMData bpm = BPMData(
            bpm: double.parse(t[1]),
            start: double.parse(t[0]) / 1000,
          );
          if (bpm.bpm < 0) {
            bpm.bpm = lstBPM * (-1) * bpm.bpm / 100;
          } else {
            lstBPM = bpm.bpm;
          }
          model.bpmList.add(bpm);
        }
      }
    }

    for (int i = 0; i < lineCount; i++) {
      model.lineList.add(LineData(LineDirection.up, flowSpeed));
    }

    List<int> xs = [];
    for (String line in data) {
      if (start) {
        List<String> t = line.split(',');
        if (t.length == 6) {
          int l = int.tryParse(t[0]) ?? 0;
          if (!xs.contains(l)) {
            xs.add(l);
          }
        } else {
          continue;
        }
      }
      if (line == "[HitObjects]") start = true;
    }
    xs.sort((x, y) => x.compareTo(y));
    start = false;

    for (String line in data) {
      if (line.isEmpty) continue;
      if (start) {
        List<String> t = line.split(',');
        double from = double.tryParse(t[2]) ?? 1 / 1000, to;
        if (t.length == 6) {
          int l = xs.indexWhere((x) => x == int.tryParse(t[0]));
          to = double.tryParse(t[5].split(':')[0]) ?? 0 / 1000;
          if (to == 0 || to <= from) {
            to = from;
          }

          double bpm = model.determineBPM(from);
          model.noteList.add(
            NoteData(
              bpm: bpm.toInt(),
              line: l,
              from: model.convertByBPM(from, 16, bpm: bpm),
              to: model.convertByBPM(to, 16, bpm: bpm),
              snd: t.last.split(':').last,
            ),
          );
        } else {
          continue;
        }
      }
      if (line == "[HitObjects]") start = true;
    }

    await model.export('$filePath.milthm');

    return true;
  }
}
