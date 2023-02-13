import 'dart:math' as math;

import 'package:animated_background/animated_background.dart';
import 'package:flutter/widgets.dart';

/// Holds the information of a bubble used in a [HubblesBehaviour].
class Hubble {
  /// The position of this bubble.
  late Offset position;

  /// The radius of this bubble.
  double? radius;

  /// The target radius of this bubble.
  late double targetRadius;

  /// The color of this bubble.
  Color? color;

  /// The state of the bubble. Is it popping?
  late bool popping;
}

/// Holds the bubbles configuration information for a [HubblesBehaviour].
class HubbleOptions {
  /// The total count of bubbles that should be spawned.
  final int bubbleCount;

  /// The minimum radius a bubble should grow to before popping.
  final double minTargetRadius;

  /// The maximum radius a bubble should grow to.
  final double maxTargetRadius;

  /// The growth rate of the bubbles.
  final double growthRate;

  /// The pop rate of the bubbles.
  final double popRate;

  /// Creates a [HubbleOptions] given a set of preferred values.
  ///
  /// Default values are assigned for arguments that are omitted.
  const HubbleOptions({
    this.bubbleCount = 100,
    this.minTargetRadius = 400.0,
    this.maxTargetRadius = 500.0,
    this.growthRate = 10.0,
    this.popRate = 150.0,
  })  : assert(bubbleCount >= 0),
        assert(minTargetRadius > 0),
        assert(maxTargetRadius > 0),
        assert(growthRate > 0),
        assert(popRate > 0);

  /// Creates a copy of this [HubbleOptions] but with the given fields
  /// replaced with new values.
  HubbleOptions copyWith({
    int? bubbleCount,
    double? minTargetRadius,
    double? maxTargetRadius,
    double? growthRate,
    double? popRate,
  }) {
    return HubbleOptions(
      bubbleCount: bubbleCount ?? this.bubbleCount,
      minTargetRadius: minTargetRadius ?? this.minTargetRadius,
      maxTargetRadius: maxTargetRadius ?? this.maxTargetRadius,
      growthRate: growthRate ?? this.growthRate,
      popRate: popRate ?? this.popRate,
    );
  }
}

/// Renders bubbles on an [AnimatedBackground].
class HubblesBehaviour extends Behaviour {
  static math.Random random = math.Random();

  static const double sqrtInverse = 0.707;

  @protected
  List<Hubble>? bubbles;
  double? deltaTargetRadius;

  /// Called when a bubble pops
  Function(bool wasTap)? onPop;

  HubbleOptions? _options;

  /// Gets the bubbles options used to configure this behaviour.
  HubbleOptions get options => _options!;

  /// Set the bubble options used to configure this behaviour.
  ///
  /// Changing this value will cause the currently spawned bubbles to update.
  set options(HubbleOptions value) {
    if (value == _options) return;
    HubbleOptions? oldOptions = _options;
    _options = value;

    onOptionsUpdate(oldOptions);
  }

  /// Creates a new bubbles behaviour.
  ///
  /// Default values will be assigned to the parameters if not specified.
  HubblesBehaviour({
    HubbleOptions options = const HubbleOptions(),
    this.onPop,
  }) {
    _options = options;
  }

  @override
  void init() {
    bubbles = generateHubbles(options.bubbleCount);
  }

  /// Generates an amount of bubbles and initializes them.
  ///
  /// This can be used to generate the initial bubbles or new bubbles when
  /// the options change
  @protected
  List<Hubble> generateHubbles(int num) {
    return List<Hubble>.generate(num, (_) {
      Hubble bubble = Hubble();
      _initHubble(bubble);
      return bubble;
    });
  }

  void _initHubble(Hubble bubble) {
    bubble.position = Offset(
      random.nextDouble() * size!.width,
      random.nextDouble() * size!.height,
    );

    var deltaTargetRadius = options.maxTargetRadius - options.minTargetRadius;
    bubble.targetRadius =
        random.nextDouble() * deltaTargetRadius + options.minTargetRadius;

    if (bubble.radius == null) {
      bubble.radius = random.nextDouble() * bubble.targetRadius;
    } else {
      bubble.radius = 0.0;
    }

    bubble.color = HSVColor.fromAHSV(
      1,
      [30.0, 220.0, 50.0, 70.0][random.nextInt(4)],
      1,
      1,
    ).toColor();
    bubble.popping = false;
  }

  void _popHubble(Hubble bubble, bool wasTap) {
    bubble.popping = true;
    bubble.radius = 0.2 * bubble.targetRadius;
    bubble.targetRadius *= 0.5;
    if (onPop != null) onPop!(wasTap);
  }

  @override
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is HubblesBehaviour) {
      bubbles = oldBehaviour.bubbles;

      onOptionsUpdate(oldBehaviour.options);
    }
  }

  /// Called when the behaviour got new options and should update accordingly.
  @protected
  @mustCallSuper
  void onOptionsUpdate(HubbleOptions? oldOptions) {
    if (bubbles == null) return;
    if (bubbles!.length > options.bubbleCount) {
      bubbles!.removeRange(0, bubbles!.length - options.bubbleCount);
    } else if (bubbles!.length < options.bubbleCount) {
      final int numToSpawn = options.bubbleCount - bubbles!.length;
      final newHubbles = generateHubbles(numToSpawn);
      bubbles!.addAll(newHubbles);
    }
  }

  @override
  bool get isInitialized => bubbles != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    Paint paint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles!) {
      paint.color = bubble.color!;
      if (!bubble.popping) {
        canvas.drawCircle(bubble.position, bubble.radius!, paint);
      } else {
        final double radiusSqrt = bubble.radius! * sqrtInverse;
        final double targetRadiusSqrt = bubble.targetRadius * sqrtInverse;
        canvas.drawLine(
          bubble.position + Offset(radiusSqrt, radiusSqrt),
          bubble.position + Offset(targetRadiusSqrt, targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(
          bubble.position + Offset(radiusSqrt, -radiusSqrt),
          bubble.position + Offset(targetRadiusSqrt, -targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(
          bubble.position + Offset(-radiusSqrt, radiusSqrt),
          bubble.position + Offset(-targetRadiusSqrt, targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(
          bubble.position + Offset(-radiusSqrt, -radiusSqrt),
          bubble.position + Offset(-targetRadiusSqrt, -targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(bubble.position + Offset(0.0, bubble.radius!),
            bubble.position + Offset(0.0, bubble.targetRadius), paint);
        canvas.drawLine(bubble.position + Offset(0.0, -bubble.radius!),
            bubble.position + Offset(0.0, -bubble.targetRadius), paint);
        canvas.drawLine(bubble.position + Offset(bubble.radius!, 0.0),
            bubble.position + Offset(bubble.targetRadius, 0.0), paint);
        canvas.drawLine(bubble.position + Offset(-bubble.radius!, 0.0),
            bubble.position + Offset(-bubble.targetRadius, 0.0), paint);
      }
    }
  }

  @override
  bool tick(double delta, Duration elapsed) {
    if (!isInitialized) return false;
    for (var bubble in bubbles!) {
      bubble.radius = bubble.radius! +
          delta * (bubble.popping ? options.popRate : options.growthRate);

      if (bubble.radius! >= bubble.targetRadius) {
        if (bubble.popping) {
          _initHubble(bubble);
        } else {
          _popHubble(bubble, false);
        }
      }
    }
    return true;
  }

  @override
  Widget builder(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return GestureDetector(
      onTapDown: (details) => _onTap(context, details.globalPosition),
      child: ConstrainedBox(
        // necessary to force gesture detector to cover screen
        constraints: BoxConstraints(
            minHeight: double.infinity, minWidth: double.infinity),
        child: super.builder(context, constraints, child),
      ),
    );
  }

  void _onTap(BuildContext context, Offset globalPosition) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var localPosition = renderBox.globalToLocal(globalPosition);
    for (var bubble in bubbles!) {
      if ((bubble.position - localPosition).distanceSquared <
          bubble.radius! * bubble.radius! * 1.2) {
        _popHubble(bubble, true);
      }
    }
  }
}
