import 'dart:convert';
import 'dart:io';
import 'package:helody/effect/fade_route.dart';
import 'package:helody/main.dart';
import 'package:helody/model/beatmap.dart';
import 'package:helody/pages/game/game_page.dart';
import 'package:helody/providers/home_provider.dart';
import 'package:helody/setting.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../widgets/button.dart';
import 'game/game_canvas.dart';

class SongPickerPage extends StatefulWidget {
  const SongPickerPage({super.key});

  @override
  State<SongPickerPage> createState() => _SongPickerPageState();
}

class _SongPickerPageState extends State<SongPickerPage> {
  List<BeatmapModel> subList = [];
  int selectedJudge = 0;

  Future<void> recursionFile(String pathName) async {
    Directory dir = Directory(pathName);

    if (!await dir.exists()) {
      return;
    }

    List<FileSystemEntity> lists = dir.listSync();
    for (FileSystemEntity entity in lists) {
      if (entity is File) {
        File file = entity;
        if (file.path.endsWith('.milthm')) {
          file.readAsString().then((fileData) {
            BeatmapModel beatmapModel =
                BeatmapModel.fromJson(jsonDecode(fileData));
            beatmapModel.dirPath = pathName;
            beatmapModel.filePath = file.path;
            subList.add(beatmapModel);
            setState(() {});
          });
        }
      } else if (entity is Directory) {
        Directory subDir = entity;
        recursionFile(subDir.path);
      }
    }
  }

  @override
  void initState() {
    BeatmapModel beatmap = HomeProvider.instance.beatmap;
    recursionFile(beatmap.dirPath);

    gamePlayer
      ?..stop()
      ..setFilePath(
          '${beatmap.dirPath}/${beatmap.audioFile ?? ''}')
      ..seek(Duration(seconds: (beatmap.previewTime ?? 0).round()))
      ..setLoopMode(LoopMode.one)
      ..play();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    subList.sort((a, b) => (a.noteList.length).compareTo(b.noteList.length));
    var beatmap = context.watch<HomeProvider>().beatmap;
    return WillPopScope(
      onWillPop: () async {
        forceStop = true;
        HomeProvider.instance.close();
        // return true;
        return false;
      },
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: GameSettings.borderRadius,
                    color: colorScheme.background,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          beatmap.title ?? '',
                          style: const TextStyle(fontSize: 24),
                        ),
                        Text(
                            '[曲]${beatmap.composer} [谱]${beatmap.beatmapper} [美]${beatmap.illustrator}'),
                        // const Text('From Re / Osu!Mania'),
                        // const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: subList.length,
                            itemBuilder: (context, index) {
                              var item = subList[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: MyButton(
                                  onPressed: () {
                                    HomeProvider.instance.selectBeatmap(subList[index]);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    decoration: (subList[index].noteList.length == HomeProvider.instance.beatmap.noteList.length)
                                        ? BoxDecoration(
                                            borderRadius:
                                                GameSettings.borderRadius,
                                            color: colorScheme.primaryContainer,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xffe8effd),
                                                Color(0xffede8fc),
                                              ],
                                              begin: Alignment(0, 0),
                                              end: Alignment(1, 1),
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 5,
                                              ),
                                            ],
                                          )
                                        : BoxDecoration(
                                            borderRadius:
                                                GameSettings.borderRadius,
                                            color: const Color(0x11000000),
                                          ),
                                    child: Row(
                                      children: [
                                        Text('${item.difficulty}'),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '判定 ',
                                    style: TextStyle(
                                      color: colorScheme.onBackground
                                          .withOpacity(0.6),
                                      fontSize: 16,
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    value: selectedJudge,
                                    underline: const SizedBox(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onBackground),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 0, child: Text('宽松')),
                                      DropdownMenuItem(
                                          value: 1, child: Text('普通')),
                                      DropdownMenuItem(
                                          value: 2, child: Text('严格')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedJudge = value ?? 0;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              MyButton(
                                onPressed: () {
                                  gamePlayer?.stop();
                                  Navigator.of(context).maybePop();
                                  Navigator.of(context).push(
                                    FadeRoute(
                                      builder: (context) => const GamePage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: GameSettings.borderRadius,
                                    gradient: GameSettings.gradient,
                                    boxShadow: const [
                                      BoxShadow(
                                        color:
                                            Color.fromARGB(255, 231, 222, 255),
                                        blurRadius: 10,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.play_arrow),
                                      SizedBox(
                                        width: 16,
                                      ),
                                      Text('开始')
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                // MyButton.icon(
                //   onPressed: () {
                //     Navigator.of(context).maybePop();
                //   },
                //   child: Container(
                //     width: 48,
                //     height: 48,
                //     alignment: Alignment.center,
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       gradient: GameSettings.gradient,
                //       boxShadow: const [
                //         BoxShadow(
                //           color: Color.fromARGB(255, 231, 222, 255),
                //           blurRadius: 10,
                //         )
                //       ],
                //     ),
                //     child: const Icon(Icons.arrow_back_ios_new),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
