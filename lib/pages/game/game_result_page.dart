import 'dart:io';

import 'package:helody/effect/fade_route.dart';
import 'package:helody/hit_judge.dart';
import 'package:helody/model/beatmap.dart';
import 'package:helody/widgets/button.dart';
import 'package:flutter/material.dart';

import '../../providers/home_provider.dart';
import 'game_page.dart';

class GameResultPage extends StatelessWidget {
  GameResultPage({Key? key, required this.result}) : super(key: key);
  final ResultData result;
  final BeatmapModel beatmap = HomeProvider.instance.beatmap;

  String evalGrade() {
    if (result.combo == result.fullCombo) {
      return 'R';
    }
    if (result.perfect2 + result.perfect == result.fullCombo) {
      return 'AP';
    }
    if (result.miss == 0) {
      return 'FC';
    }
    if (score >= 1000000) {
      return 'S';
    } else if (score >= 920000) {
      return 'A';
    } else if (score >= 870000) {
      return 'B';
    } else if (score >= 820000) {
      return 'C';
    } else {
      return 'F';
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> resultCountList = {
      'Perfect+': result.perfect2,
      'Perfect': result.perfect,
      'Good': result.good,
      'Bad': result.bad,
      'Miss': result.miss,
      'MaxCombo': result.maxCombo,
      'Early': result.early,
      'Late': result.late,
    };

    return Material(
      child: Row(
        children: [
          Expanded(
            child: Image.file(
              File('${beatmap.dirPath}/${beatmap.illustrationFile ?? ''}'),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            beatmap.title ?? "",
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            beatmap.difficulty ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 233, 223, 255),
                              Color.fromARGB(255, 202, 178, 255),
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
                        child: Text(
                          evalGrade(),
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 32,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 32,
                        ),
                        itemCount: resultCountList.length,
                        itemBuilder: (context, index) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(resultCountList.keys.toList()[index],
                                style: const TextStyle(fontSize: 16)),
                            Text(
                              resultCountList.values.toList()[index].toString(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MyButton.icon(
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 233, 223, 255),
                                  Color.fromARGB(255, 202, 178, 255),
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
                              Icons.arrow_back_ios_new,
                              size: 32,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
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
                                  Color.fromARGB(255, 255, 187, 0),
                                  Color.fromARGB(255, 255, 149, 0),
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
                              Icons.restart_alt,
                              size: 32,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                                FadeRoute(builder: (context) => GamePage()));
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
