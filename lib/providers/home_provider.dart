import 'package:flutter/material.dart';
import 'package:helody/model/beatmap.dart';

Widget? _subPage;
bool _showSubPage = false;
BeatmapModel _beatmap = BeatmapModel();

class HomeProvider extends ChangeNotifier {
  static late HomeProvider instance;

  get subPage => _subPage;

  get showSubPage => _showSubPage;
  get beatmap => _beatmap;
  double animatedOpacityValue = 0.3;

  void setSubPage(Widget? page) {
    _subPage = page;
    animatedOpacityValue = 0.3;
    Future.delayed(
      const Duration(milliseconds: 100),
    ).then((value) {
      animatedOpacityValue = 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void selectBeatmap(BeatmapModel beatmap) {
    _beatmap = beatmap;
    notifyListeners();
  }

  void close() {
    _showSubPage = false;
    notifyListeners();
  }

  void show() {
    _showSubPage = true;
    notifyListeners();
  }
}
