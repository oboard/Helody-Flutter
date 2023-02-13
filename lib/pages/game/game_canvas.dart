import 'dart:ui' as ui;

import 'package:helody/main.dart';
import 'package:helody/model/beatmap.dart';
import 'package:flutter/material.dart';

import 'game_page.dart';

bool forceStop = false;

class GameCanvas extends StatelessWidget {
  final BeatmapModel beatmap;

  const GameCanvas({super.key, required this.beatmap});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size * 0.8;
    double singleW = size.width / (maxCol + 1);
    xs = List.generate(maxCol + 1, (index) => singleW * (index + 0.5));
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: GamePainter(beatmap),
    );
  }
}

int getCurrentPosition() {
  return gamePlayer?.position.inMilliseconds ?? (getCurrentTime() - startTime);
}

double getCurrentBPos(BeatmapModel beatmap) {
  int pos = getCurrentPosition();
  double bpm = beatmap.determineBPM(pos / 1000);
  return pos * bpm / 60;
}

class GamePainter extends CustomPainter {
  final BeatmapModel beatmap;

  GamePainter(this.beatmap);
  @override
  void paint(Canvas canvas, Size size) {
    int pos = getCurrentPosition();
    double bpm = beatmap.determineBPM(pos / 1000);
    int pos1 = 0, pos2 = 0;
    double bpos = getCurrentBPos(beatmap);

    for (var note in beatmap.noteList) {
      if (pos1 == 0) {
        if (note.from[0] > bpos - 20 * bpm) {
          pos1 = beatmap.noteList.indexOf(note);
        }
      }
      if (pos2 == 0) {
        if (note.to[0] > bpos + 50 * bpm) {
          pos2 = beatmap.noteList.indexOf(note);
        }
      }
    }
    if (pos1 > beatmap.noteList.length) pos1 = beatmap.noteList.length;
    if (pos2 > beatmap.noteList.length) pos2 = beatmap.noteList.length;
    // print(pos / 1000);
    // print(bpos);

    List<List<Offset>> lines = [];
    for (var e in beatmap.noteList.getRange(pos1, pos2)) {
      if (e.judged && e.from[0] == e.to[0]) continue;
      lines.add([
        Offset(xs[e.line], size.height - (e.from[0] - bpos) / 10),
        Offset(xs[e.line], size.height - (e.to[0] - bpos) / 10),
      ]);
    }
    // 绘制点
    for (var line in lines) {
      canvas.drawLine(
        line[0],
        line[1],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 48.0,
      );
      canvas.drawLine(
        line[0],
        line[1],
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(1, 1),
            [
              const Color(0xffe8effd),
              const Color(0xffede8fc),
            ],
          )
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 40.0,
      );
    }
    // 绘制
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
