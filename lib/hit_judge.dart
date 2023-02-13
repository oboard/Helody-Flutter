import 'package:helody/setting.dart';

class ResultData {
  int mHP = 100;
  bool dangerHiding = false;
  int missContinuous = 0;
  int fullCombo = 0;
  int perfect2 = 0, perfect = 0, good = 0, bad = 0, miss = 0;
  int maxCombo = 0, combo = 0, hit = 0;
  int early = 0, late = 0;

  bool dead = false;
  DateTime? deadTime;

  int get HP {
    return mHP;
  }

  set HP(int value) {
    mHP = value;
    if (mHP > 100) {
      mHP = 100;
    }
    if (value < 50) {
// if (!GamePlayLoops.instance.dangerAni.gameObject.activeSelf) {
// GamePlayLoops.instance.dangerAni.gameObject.active = true;
// }
// } else {
// if (GamePlayLoops.instance.dangerAni.gameObject.activeSelf) {
// if (!dangerHiding) {
// GamePlayLoops.instance.dangerAni.play("HideDanger", 0, 0.0);
// }
      dangerHiding = true;
    } else {
      dangerHiding = false;
    }
    if (value <= 0 && !dead) {
      dead = true;
      deadTime = DateTime.now();
// if (!dangerHiding) {
// GamePlayLoops.instance.dangerAni.play("HideDanger", 0, 0.0);
// }
// SndPlayer.play("Fail");
// GamePlayLoops.instance.summaryInfo.updateInfo();
// BeatmapLoader.instance.audio.pause();
// GamePlayLoops.instance.summaryAni.play("DeadShow", 0, 0.0);
      mHP = 0;
    }
  }

  int judgeRange = 1;

  int get score {
    if (fullCombo == 0) {
      return 0;
    }
    double orScore = originScore;
    double judgeBuff = 1.0;
    if (judgeRange == 0) {
      judgeBuff = 0.8;
    } else if (judgeRange == 1) {
      judgeBuff = 1.0;
    } else if (judgeRange == 2) {
      judgeBuff = 1.2;
    }
    return (orScore * judgeBuff).round();
  }

  double get originScore {
    return (maxCombo * 1.0 / fullCombo) * 110000 +
        ((perfect2 * 1.1 + perfect * 1.0) / fullCombo +
                good * 1.0 / fullCombo * 0.6 +
                bad * 1.0 / fullCombo * 0.1) *
            900000;
  }

  double get accuracy {
    if (hit == 0) {
      return 0;
    }
    return ((perfect2 + perfect) * 1.0 + good * 0.75 + bad * 0.5) / hit;
  }
}

class HitJudge {
// static GameObject perfect, good, miss, perfect2;
  static ResultData result = ResultData();
  static double judgeArea = 0;
  static int judgeRange = 1;
  static bool record = false;
  static bool noDead = false;
  static bool missed = false;
  static void judge(double deltaTime, String snd) {
    bool miss = false;
    double absDeltaTime = deltaTime.abs();
    print(deltaTime);
    if (absDeltaTime <= GameSettings.Perfect2) {
      result.perfect2++;
      result.HP += 3;
    } else if (absDeltaTime <= GameSettings.Perect) {
      result.perfect++;
      result.HP += 2;
    } else if (absDeltaTime <= GameSettings.Good) {
      result.good++;
      result.HP += 1;
      if (deltaTime > 0) {
        result.late++;
// GamePlayLoops.Instance.late.setActive(false);
// GamePlayLoops.Instance.late.setActive(true);
      } else {
        result.early++;
// GamePlayLoops.Instance.early.setActive(false);
// GamePlayLoops.Instance.early.setActive(true);
      }
    } else if (absDeltaTime <= GameSettings.Bad) {
      result.bad++;
      result.combo = -1;
      if (deltaTime > 0) {
        result.late++;
// GamePlayLoops.Instance.late.setActive(false);
// GamePlayLoops.Instance.late.setActive(true);
      } else {
        result.early++;
// GamePlayLoops.Instance.early.setActive(false);
// GamePlayLoops.Instance.early.setActive(true);
      }
    } else {
// if (Record) {
// if (note is TapController)
// RecordLog.AppendLine("[AutoMiss-Tooearly] " + note.Index + "(Tap) Missed");
// else if (note is HoldController)
// RecordLog.AppendLine("[AutoMiss-Tooearly] " + note.Index + "(Hold) Missed");
// }

      result.combo = 0;
      miss = true;
      result.miss++;
      missed = true;
      result.missContinuous++;
      if (!noDead) result.HP -= 7;
      if (deltaTime > 0) {
        result.late++;
      } else {
        result.early++;
      }
    }
    if (!miss) {
      result.combo++;
      if (result.combo > result.maxCombo) result.maxCombo = result.combo;
      result.missContinuous = 0;
      if (result.combo % 100 == 0 || result.combo == 50) {
        // GamePlayLoops.Instance.ComboTip.text = Result.Combo + " COMBO";
        // GamePlayLoops.Instance.ComboTip.gameObject.SetActive(true);
      }
    }
  }
}
