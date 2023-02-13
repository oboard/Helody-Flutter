import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../setting.dart';

const Duration kFadeOutDuration = Duration(milliseconds: 50);
const Duration kFadeInDuration = Duration(milliseconds: 200);
const Duration kScaleOutDuration = Duration(milliseconds: 0);
const Duration kScaleInDuration = Duration(milliseconds: 500);
final Tween<double> _opacityTween = Tween<double>(begin: 1.0, end: 0.5);
final Tween<double> _scaleTween = Tween<double>(begin: 1.0, end: 0.9);
const double kMinInteractiveDimensionLazy = 44;

class MyButton extends StatefulWidget {
  const MyButton({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.disabledColor,
    this.align = Alignment.center,
    this.borderRadius,
    this.onPressed,
    this.icon,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  })  : isIcon = false,
        super(key: key);

  const MyButton.icon({
    Key? key,
    this.child,
    this.padding,
    this.disabledColor,
    this.borderRadius,
    required this.onPressed,
    this.icon,
    this.align = Alignment.center,
    this.onTapUp,
    this.onTapDown,
    this.onTapCancel,
  })  : color = null,
        isIcon = true,
        super(key: key);

  final Widget? child;
  final Widget? icon;
  final Alignment align;

  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? disabledColor;
  final VoidCallback? onPressed;
  final GestureTapUpCallback? onTapUp;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCancelCallback? onTapCancel;

  final BorderRadius? borderRadius;
  final bool isIcon;

  bool get enabled => onPressed != null;

  @override
  MyButtonState createState() => MyButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class MyButtonState extends State<MyButton> with TickerProviderStateMixin {
  AnimationController? _animationController;
  late Animation<double> _scaleAnimation;
  bool _hovering = false;
  MaterialStatesController statesController = MaterialStatesController();
  bool _buttonHeldDown = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 0.0,
      vsync: this,
    );
    _scaleAnimation = _animationController!
        .drive(CurveTween(curve: Curves.easeInOut))
        .drive(_scaleTween);
  }

  @override
  void dispose() {
    _animationController!.dispose();
    _animationController = null;
    super.dispose();
  }

  void handleTapDown(TapDownDetails event) {
    widget.onTapDown?.call(event);
    if (!_buttonHeldDown) {
      _buttonHeldDown = true;
      _animate();
    }
  }

  void handleTapUp(TapUpDetails event) {
    widget.onTapUp?.call(event);
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void handleTapCancel() {
    widget.onTapCancel?.call();
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _animate() {
    if (_animationController!.isAnimating) return;
    final bool wasHeldDown = _buttonHeldDown;
    final TickerFuture ticker = _buttonHeldDown
        ? _animationController!.animateTo(1.0, duration: kScaleOutDuration)
        : _animationController!.animateTo(0.0, duration: kScaleInDuration);
    ticker.then<void>((void value) {
      if (mounted && wasHeldDown != _buttonHeldDown) _animate();
    });
  }

  void handleMouseEnter(PointerEnterEvent event) {
    _hovering = true;
    if (widget.enabled) {
      if (mounted) setState(() {});
    }
  }

  void handleMouseExit(PointerExitEvent event) {
    _hovering = false;
    if (mounted) setState(() {});
  }

  void handleFocusUpdate(bool hasFocus) {
    _hasFocus = hasFocus;
    // Set here rather than updateHighlight because this widget's
    // (MaterialState) states include MaterialState.focused if
    // the InkWell _has_ the focus, rather than if it's showing
    // the focus per FocusManager.instance.highlightMode.
    statesController.update(MaterialState.focused, hasFocus);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;

    final ThemeData theme = Theme.of(context);
    Color currentColor = theme.primaryColor;
    if (!enabled) currentColor = widget.disabledColor ?? theme.disabledColor;
    final MouseCursor effectiveMouseCursor =
        MaterialStateProperty.resolveAs<MouseCursor>(
      MaterialStateMouseCursor.clickable,
      statesController.value,
    );
    return Focus(
      // focusNode: widget.focusNode,
      // canRequestFocus: _canRequestFocus,
      onFocusChange: handleFocusUpdate,
      // autofocus: widget.autofocus,
      child: MouseRegion(
        cursor: effectiveMouseCursor,
        onEnter: handleMouseEnter,
        onExit: handleMouseExit,
        child: Semantics(
          onTap: enabled ? widget.onPressed : null,
          child: GestureDetector(
            onTapDown: enabled ? handleTapDown : null,
            onTapUp: enabled ? handleTapUp : null,
            onTap: enabled ? widget.onPressed : null,
            onTapCancel: enabled ? handleTapCancel : null,
            behavior: HitTestBehavior.deferToChild,
            excludeFromSemantics: true,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  AnimatedScale(
                    scale: (_hasFocus || _hovering) ? 1.1 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: widget.padding ?? EdgeInsets.zero,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
