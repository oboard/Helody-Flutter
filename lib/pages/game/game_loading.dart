import 'package:helody/effect/fade_route.dart';
import 'package:helody/main.dart';
import 'package:helody/model/beatmap.dart';
import 'package:flutter/material.dart';
import 'package:helody/providers/home_provider.dart';
import 'package:just_audio/just_audio.dart';

import 'game_page.dart';

class GameLoading extends StatefulWidget {
  const GameLoading({Key? key}) : super(key: key);

  @override
  State<GameLoading> createState() => _GameLoadingState();
}

class _GameLoadingState extends State<GameLoading> {
  @override
  void initState() {
    super.initState();
    state = GameState.loading;
    countData();
    gamePlayer
      ?..stop()
      ..setFilePath('${beatmapNow.dirPath}/${beatmapNow.audioFile ?? ''}')
      ..load().then((value) {
        gamePlayer
          ?..setLoopMode(LoopMode.off)
          ..seek(Duration.zero)
          ..pause();
      });
    Future.delayed(const Duration(seconds: 2)).then((value) {
      state = GameState.playing;
      Navigator.of(context).pushReplacement(
        FadeRoute(
          builder: (context) => const GamePage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final BeatmapModel beatmap = beatmapNow;
    return SizedBox(
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 16,
          shadows: [
            BoxShadow(
              blurRadius: 8,
              spreadRadius: 50,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              beatmap.title ?? '',
              style: const TextStyle(fontSize: 32),
            ),
            Text(beatmap.beatmapper ?? ''),
            const Text(''),
            const Text('...'),
          ],
        ),
      ),
    );
  }
}
