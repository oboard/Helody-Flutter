import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:helody/loader/directory_create.dart';
import 'package:helody/loader/path.dart';
import 'package:helody/model/beatmap.dart' hide LineDirection;
import 'package:helody/pages/song_picker.dart';
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
                    // AnimatedBackground(
                    //   behaviour: HubblesBehaviour(),
                    //   vsync: this,
                    //   child: const SizedBox(),
                    // ),
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
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              itemCount: songList.length,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                        pickSongFile()
                                            .then((value) => gameLoad());
                                      },
                                      child: Container(
                                        width: size.width / 4,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 32,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              GameSettings.borderRadius,
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
                                          builder: (context) =>
                                              CupertinoAlertDialog(
                                            title: const Text('确认删除？'),
                                            actions: [
                                              CupertinoDialogAction(
                                                isDestructiveAction: true,
                                                onPressed: () {
                                                  Directory(
                                                          beatmapModel.dirPath)
                                                      .deleteSync(
                                                          recursive: true);
                                                  gameLoad();
                                                  setState(() {});
                                                  Navigator.of(context)
                                                      .maybePop();
                                                },
                                                child: const Text(
                                                  '确定',
                                                ),
                                              ),
                                              CupertinoDialogAction(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .maybePop();
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
                                              margin:
                                                  const EdgeInsets.symmetric(
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
                                                            GameSettings
                                                                .borderRadius,
                                                        child: Image.file(
                                                          File(
                                                              '${beatmapModel.dirPath}/${beatmapModel.illustrationFile ?? ''}'),
                                                          fit: BoxFit.cover,
                                                          height:
                                                              double.infinity,
                                                          width:
                                                              double.infinity,
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
                                              left: 64,
                                              right: 64,
                                              bottom: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        beatmapModel.title ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            color: Color(
                                                                0xffffffff)),
                                                      ),
                                                      Text(
                                                        beatmapModel
                                                                .beatmapper ??
                                                            '',
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0x66ffffff)),
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
                      Consumer<HomeProvider>(
                          builder: (context, provider, child) {
                        return SizedBox(
                          width:
                              (provider.subPage != null || provider.showSubPage)
                                  ? size.width / 2
                                  : 0,
                          child: Dismissible(
                            key: GlobalKey(),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                HomeProvider.instance.setSubPage(null);
                                HomeProvider.instance.close();
                              }
                              return false;
                            },
                            child: (provider.subPage == null)
                                ? const SizedBox()
                                : provider.subPage,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void openSongMenu(BeatmapModel beatmapModel) {
    HomeProvider.instance.setSubPage(const SongPickerPage());
    HomeProvider.instance.selectBeatmap(beatmapModel);
    HomeProvider.instance.show();
  }
}
