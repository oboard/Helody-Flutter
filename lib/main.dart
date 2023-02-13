import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:helody/effect/fade_route.dart';
import 'package:helody/loader/directory_create.dart';
import 'package:helody/loader/path.dart';
import 'package:helody/model/beatmap.dart' hide LineDirection;
import 'package:helody/pages/game/game_loading.dart';
import 'package:helody/providers/home_provider.dart';
import 'package:helody/setting.dart';
import 'package:helody/widgets/button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'loader/file_picker.dart';

AudioPlayer? gamePlayer;
List<BeatmapModel> subList = [];
int selectedJudge = 0;

loadMusic() async {
  if (gamePlayer != null) {
    if (gamePlayer!.playing) {
      gamePlayer?.stop();
    }
  }
  gamePlayer ??= AudioPlayer();
  var content = await rootBundle.load("sounds/SongSelect.mp3");
  final directory = await getApplicationDocumentsDirectory();

  var file = File("${directory.path}/SongSelect.mp3");
  await file.writeAsBytes(content.buffer.asUint8List());
  //发出提示音
  gamePlayer
    ?..setFilePath(file.path) //;..setUrl('asset:///sounds/SongSelect.mp3')
    ..setLoopMode(LoopMode.one)
    ..play();
}

void main() {
  runApp(const Game());
}

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: 'Helody',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

var menu = [
  Icons.settings,
  Icons.edit_location_alt_outlined,
  Icons.cloud,
];

int pageIndex = 0;
List<BeatmapModel> songList = [BeatmapModel()];

class _HomeState extends State<Home> with TickerProviderStateMixin {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      //默认隐藏，若从边缘滑动会显示，过会儿会自动隐藏（安卓，iOS）
      SystemUiMode.immersiveSticky,
    );
    // 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    gameLoad();
    super.initState();
    HomeProvider.instance = Provider.of<HomeProvider>(context, listen: false);
  }

  var loaded = false;

  String gamePath = '';

  void recursionFile(String pathName) {
    Directory dir = Directory(pathName);

    if (!dir.existsSync()) {
      return;
    }

    List<FileSystemEntity> lists = dir.listSync();
    List<String> haveLoaded = [];
    for (FileSystemEntity entity in lists) {
      if (entity is File) {
        File file = entity;
        if (file.path.endsWith('milthm')) {
          BeatmapModel beatmapModel =
              BeatmapModel.fromJson(jsonDecode(file.readAsStringSync()));
          beatmapModel.dirPath = pathName;
          beatmapModel.filePath = file.path;
          if (!haveLoaded.any((element) => element.contains(pathName))) {
            songList.add(beatmapModel);
            haveLoaded.add(pathName);
            if (mounted) setState(() {});
          }
        }
      } else if (entity is Directory) {
        Directory subDir = entity;
        recursionFile(subDir.path);
      }
    }
  }

  Future<void> gameLoad() async {
    await checkAndCreateImportDictory();
    gamePath = await getGamePath();

    songList.clear();
    recursionFile(gamePath);
    songList.add(BeatmapModel());

    loadMusic();

    loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    var beatmap = beatmapNow;
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (!loaded) gameLoad();
        },
        child: Stack(
          children: [
            SizedBox.fromSize(
              size: size,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Stack(
                  children: const [
                    Image(
                      image: AssetImage('images/background.jpg'),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.black38,
            ),
            Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Container(
                    color: const Color(0xee222222),
                    child: Row(
                      children: [
                        for (IconData item in menu)
                          MyButton.icon(
                            padding: EdgeInsets.zero,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                item,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              pageIndex = menu.indexOf(item);
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        physics: const BouncingScrollPhysics(),
                        itemCount: songList.length,
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 16,
                          right: size.width / 2 + 16,
                        ),
                        itemBuilder: (context, index) {
                          BeatmapModel beatmapModel = songList[index];
                          if (index == songList.length - 1) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              child: MyButton(
                                onPressed: () {
                                  pickSongFile().then((value) => gameLoad());
                                },
                                child: Container(
                                  width: size.width / 4,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: GameSettings.borderRadius,
                                    gradient: GameSettings.gradient,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '点击此处导入谱面',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return MyButton(
                            onPressed: () => openSongMenu(beatmapModel),
                            child: SizedBox(
                              width: size.width / 4,
                              child: GestureDetector(
                                onLongPress: () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('确认删除？'),
                                      actions: [
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          onPressed: () {
                                            Directory(beatmapModel.dirPath)
                                                .deleteSync(recursive: true);
                                            gameLoad();
                                            setState(() {});
                                            Navigator.of(context).maybePop();
                                          },
                                          child: const Text(
                                            '确定',
                                          ),
                                        ),
                                        CupertinoDialogAction(
                                          onPressed: () {
                                            Navigator.of(context).maybePop();
                                          },
                                          child: const Text('取消'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 16,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                GameSettings.borderRadius,
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                GameSettings.borderRadius,
                                            child: Stack(
                                              children: [
                                                // Text(
                                                //     '${beatmapModel.dirPath}/${beatmapModel.illustrationFile ?? ''}'),
                                                ClipRRect(
                                                  borderRadius:
                                                      GameSettings.borderRadius,
                                                  child: Image.file(
                                                    File(
                                                        '${beatmapModel.dirPath}/${beatmapModel.illustrationFile ?? ''}'),
                                                    fit: BoxFit.cover,
                                                    height: double.infinity,
                                                    width: double.infinity,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  beatmapModel.title ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xffffffff)),
                                                ),
                                                Text(
                                                  beatmapModel.beatmapper ?? '',
                                                  style: const TextStyle(
                                                      color: Color(0x66ffffff)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child:
                  Consumer<HomeProvider>(builder: (context, provider, child) {
                return SizedBox(
                  width: size.width / 2,
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
                                    beatmapNow.title ?? '',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  Text(
                                      '[曲]${beatmapNow.composer} [谱]${beatmapNow.beatmapper} [美]${beatmapNow.illustrator}'),
                                  // const Text('From Re / Osu!Mania'),
                                  // const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: subList.length,
                                      itemBuilder: (context, index) {
                                        var item = subList[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: MyButton(
                                            onPressed: () {
                                              HomeProvider.instance
                                                  .selectBeatmap(
                                                      subList[index]);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 16,
                                              ),
                                              decoration: (subList[index]
                                                          .noteList
                                                          .length ==
                                                      HomeProvider
                                                          .instance
                                                          .beatmap
                                                          .noteList
                                                          .length)
                                                  ? BoxDecoration(
                                                      borderRadius: GameSettings
                                                          .borderRadius,
                                                      color: colorScheme
                                                          .primaryContainer,
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xffe8effd),
                                                          Color(0xffede8fc),
                                                        ],
                                                        begin: Alignment(0, 0),
                                                        end: Alignment(1, 1),
                                                      ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color:
                                                              Color(0x22000000),
                                                          blurRadius: 5,
                                                        ),
                                                      ],
                                                    )
                                                  : BoxDecoration(
                                                      borderRadius: GameSettings
                                                          .borderRadius,
                                                      color: const Color(
                                                          0x11000000),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                  color:
                                                      colorScheme.onBackground),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 0,
                                                    child: Text('宽松')),
                                                DropdownMenuItem(
                                                    value: 1,
                                                    child: Text('普通')),
                                                DropdownMenuItem(
                                                    value: 2,
                                                    child: Text('严格')),
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
                                                builder: (context) =>
                                                    const GameLoading(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: 48,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  GameSettings.borderRadius,
                                              gradient: GameSettings.gradient,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color.fromARGB(
                                                      255, 231, 222, 255),
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
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void openSongMenu(BeatmapModel beatmap) {
    HomeProvider.instance.selectBeatmap(beatmap, isParent: true);
  }
}
