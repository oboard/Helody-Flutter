import 'package:helody/effect/cool_route.dart';
import 'package:helody/effect/fade_route.dart';
import 'package:helody/hit_judge.dart';
import 'package:helody/main.dart';
import 'package:helody/model/beatmap.dart';
import 'package:helody/pages/game/game_canvas.dart';
import 'package:helody/pages/game/game_page.dart';
import 'package:helody/providers/home_provider.dart';
import 'package:helody/setting.dart';
import 'package:helody/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameOverlay extends StatefulWidget {
  const GameOverlay({super.key});

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  countScore() {
    percent = (gamePlayer?.position.inMilliseconds ?? 0) /
        (gamePlayer?.duration?.inMilliseconds ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyButton.icon(
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x44444444),
                ),
                child: const Icon(
                  Icons.pause,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              onPressed: () {
                if (!(gamePlayer?.playing ?? true)) return;
                state = GameState.pause;
                gamePlayer?.pause();

                setState(() {});
              },
            ),
            Text(
              '${HitJudge.result.combo} COMBO',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            Column(
              children: [
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Color(0x44000000),
                    fontSize: 16,
                  ),
                )
              ],
            )
          ],
        ),
        AnimatedCrossFade(
          firstChild: Stack(),
          secondChild: Stack(
            children: [
              Container(
                color: const Color(0x44000000),
              ),
              if (state == GameState.pause)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: 32,
                    spacing: 32,
                    children: [
                      MyButton.icon(
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: GameSettings.gradient,
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(255, 231, 222, 255),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 32,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).maybePop();
                        },
                      ),
                      MyButton.icon(
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: GameSettings.gradient,
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(255, 231, 222, 255),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.restart_alt,
                            size: 32,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            FadeRoute(
                              builder: (context) => GamePage(
                                beatmap: context.watch<HomeProvider>().beatmap,
                              ),
                            ),
                          );
                        },
                      ),
                      MyButton.icon(
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 170, 156, 255),
                                Color.fromARGB(255, 215, 140, 255),
                              ],
                              begin: Alignment(0, 0),
                              end: Alignment(1, 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(255, 231, 222, 255),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_outlined,
                            size: 32,
                          ),
                        ),
                        onPressed: () {
                          state = GameState.playing;
                          gamePlayer?.play();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
          crossFadeState: state == GameState.pause
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 500),
        ),
        if (state == GameState.playing)
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.9,
              widthFactor: 0.8,
              child: Stack(
                children: [
                  Row(
                    children: List.generate(
                      maxCol + 1,
                      (index) => Expanded(
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) {
                            BeatmapModel beatmap = HomeProvider.instance.beatmap;
                            print('66');
                            double currentBPos =
                                getCurrentBPos(beatmap);
                            pressing[index] = currentBPos;

                            setState(() {});
                            NoteData? closestNote =
                                getClosetNote(beatmap, index);
                            print(closestNote?.snd);
                            if (closestNote == null) return;
                            HitJudge.judge(
                                (closestNote.from[0] - currentBPos) / 10000,
                                closestNote.snd);
                            closestNote.judged = true;
                          },
                          onPointerUp: (event) {
                            pressing[index] = 0;
                            setState(() {});
                          },
                          child: Column(
                            children: [
                              // Text('$index'),
                              Expanded(
                                child: Container(),
                              ),
                              Container(
                                height: 64,
                                width: 64,
                                // decoration: BoxDecoration(
                                //   shape: BoxShape.circle,
                                //   color: null,
                                //   // boxShadow: [
                                //   //   if (pressing[index]) ...[
                                //   //     const BoxShadow(
                                //   //       color: Colors.black,
                                //   //       blurRadius: 16,
                                //   //     ),
                                //   //   ],
                                //   // ],
                                //   // border: Border.all(
                                //   //   width: 4,
                                //   //   color: Colors.black45,
                                //   // ),
                                // ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

NoteData? getClosetNote(BeatmapModel beatmap, int index) {
  int pos1 = 0;
  double bpos = getCurrentBPos(beatmap);

  NoteData? last = beatmap.noteList[0];
  for (var note in beatmap.noteList) {
    if (pos1 == 0) {
      if (note.from[0] > bpos && note.line == index) {
        if (last != null) {
          if ((last.from[0] - bpos).abs() < (note.from[0] - bpos).abs()) {
            return last;
          }
        }
        return note;
      }
      if (note.line == index) last = note;
    }
  }
  return null;
}
