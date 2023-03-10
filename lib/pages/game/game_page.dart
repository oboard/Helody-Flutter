import 'dart:io';
import 'dart:ui';

import 'package:helody/effect/fade_route.dart';
import 'package:helody/hit_judge.dart';
import 'package:helody/main.dart';

import 'package:helody/pages/game/game_result_page.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:helody/providers/home_provider.dart';

import 'game_canvas.dart';
import 'game_overlay.dart';

GameState state = GameState.loading;

enum GameState { playing, pause, loading }

int startTime = 0;
int maxCol = 0;
List<double> xs = [];
List<double> pressing = [];

int score = 0;
double percent = 0.00;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

int getCurrentTime() {
  return DateTime.now().millisecondsSinceEpoch;
}

countData() {
  maxCol = 0;
  HitJudge.result = ResultData();
  forceStop = false;
  startTime = getCurrentTime();
  for (var note in beatmapNow.noteList) {
    note.judged = false;
    if (note.line > maxCol) maxCol = note.line;
  }
  pressing = List.generate(maxCol + 1, (index) => 0);
  print(maxCol);
}

class _GamePageState extends State<GamePage> {
  refresh() {
    Future.delayed(const Duration(milliseconds: 5)).then((value) {
      if (forceStop) return;
      if (mounted && state == GameState.playing) setState(() {});

      Duration? duration = gamePlayer?.duration;
      if (duration != null) {
        if (gamePlayer!.position > duration) {
          // A->B->C B被C替换
          Navigator.of(context).pushReplacement(
            FadeRoute(
              builder: (context) => GameResultPage(
                result: HitJudge.result,
              ),
            ),
          );
          return;
        }
      }
      refresh();
    });
  }

  @override
  void initState() {
    startGame();

    super.initState();
    refresh();
  }

  void startGame() {
    Future.delayed(const Duration(seconds: 2)).then((value) {
      if (mounted) {
        state = GameState.playing;
        setState(() {});
        gamePlayer?.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var beatmap = HomeProvider.instance.beatmap;
    return WillPopScope(
      onWillPop: () async {
        if (state == GameState.playing) {
          state = GameState.pause;
          setState(() {});
          return false;
        }
        forceStop = true;
        gamePlayer?.stop();
        return true;
        // return false;
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Image.file(
              File('${beatmap.dirPath}/${beatmap.illustrationFile ?? ''}'),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.9,
                widthFactor: 0.8,
                child: Stack(
                  children: [
                    // Row(
                    //   children: List.generate(
                    //     maxCol + 1,
                    //     (index) => Expanded(
                    //       child: Stack(
                    //         alignment: Alignment.center,
                    //         children: [
                    //           Column(
                    //             children: [
                    //               // Text('$index'),
                    //               Expanded(
                    //                 child: Container(
                    //                   width: 4,
                    //                   color: Colors.grey,
                    //                 ),
                    //               ),
                    //               Container(
                    //                 height: 64,
                    //                 width: 64,
                    //                 decoration: BoxDecoration(
                    //                   shape: BoxShape.circle,
                    //                   color: Colors.white,
                    //                   border: Border.all(
                    //                     width: 4,
                    //                     color: Colors.black45,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //           if (pressing[index] != 0)
                    //             Container(
                    //               width: 64,
                    //               decoration: BoxDecoration(
                    //                 borderRadius: BorderRadius.circular(64),
                    //                 gradient: const LinearGradient(
                    //                   colors: [
                    //                     Colors.transparent,
                    //                     Color.fromARGB(56, 164, 108, 255),
                    //                   ],
                    //                   begin: Alignment.topCenter,
                    //                   end: Alignment.bottomCenter,
                    //                 ),
                    //               ),
                    //             )
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    GameCanvas(
                      beatmap: beatmap,
                    ),
                  ],
                ),
              ),
            ),
            const GameOverlay(),
          ],
        ),
      ),
    );
  }
}
