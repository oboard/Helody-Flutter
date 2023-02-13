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

  void setSubPage(Widget? page) {
    _subPage = page;
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
