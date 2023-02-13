import 'package:helody/model/beatmap.dart';
import 'package:flutter/material.dart';

class GameLoading extends StatelessWidget {
  const GameLoading({Key? key, required this.beatmap}) : super(key: key);

  final BeatmapModel beatmap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width:double.infinity,height: double.infinity,
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
              style: const TextStyle(
                fontSize: 32
              ),
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
