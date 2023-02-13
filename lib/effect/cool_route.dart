import 'dart:ui';

import 'package:flutter/material.dart';

class CoolRoute<T> extends PageRoute<T> {
  CoolRoute({
    required this.builder,
    RouteSettings? settings,
    this.maintainState = true,
  }) : super(settings: settings);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 1000);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = builder(context);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return BlurTransitionsBuilder().buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _FadeUpwardsPageTransition extends StatelessWidget {
  _FadeUpwardsPageTransition({
    Key? key,
    required Animation<double>
        routeAnimation, // The route's linear 0.0 - 1.0 animation.
    this.child,
  })  : _positionAnimation =
            routeAnimation.drive(_bottomUpTween.chain(_easeInTween)),
        _opacityAnimation = routeAnimation.drive(_easeInTween),
        _scaleAnimation = routeAnimation.drive(_scaleTween.chain(_easeInTween)),
        _rotateAnimation =
            routeAnimation.drive(_rotateTween.chain(_easeInTween)),
        super(key: key);

  // Fractional offset from 1/4 screen below the top to fully on screen.
  static final Tween<Offset> _bottomUpTween = Tween<Offset>(
    begin: const Offset(1, 0.0),
    end: Offset.zero,
  );
  static final Tween<double> _rotateTween = Tween<double>(
    begin: 0.05,
    end: 0,
  );
  static final Tween<double> _scaleTween = Tween<double>(
    begin: 0.3,
    end: 1,
  );
  static final Animatable<double> _fastOutSlowInTween =
      CurveTween(curve: Curves.easeInOutCirc);
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeInOutCirc);

  final Animation<Offset> _positionAnimation;
  final Animation<double> _opacityAnimation;
  final Animation<double> _rotateAnimation;
  final Animation<double> _scaleAnimation;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: _opacityAnimation.value * 16,
        sigmaY: _opacityAnimation.value * 16,
      ),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: child,
      ),
    );
  }
}

class BlurTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return _FadeUpwardsPageTransition(
      routeAnimation: animation,
      child: child,
    );
  }
}
