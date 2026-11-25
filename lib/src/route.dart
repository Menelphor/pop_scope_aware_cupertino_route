// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a modified copy of the `route.dart` file of `package:cupertino_ui`.

import 'dart:math';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

const double _kBackGestureWidth = 20.0;
const double _kMaxSwipeDistance = 0.42; // As portion of screen.
const double _kMinFlingVelocity = 1.0; // Screen widths per second.

// The duration for a page to animate when the user releases it mid-swipe.
const Duration _kDroppedSwipePageAnimationDuration = Duration(
  milliseconds: 350,
);

/// Barrier color used for a barrier visible during transitions for Cupertino
/// page routes.
///
/// This barrier color is only used for full-screen page routes with
/// `fullscreenDialog: false`.
///
/// A relatively rigorous eyeball estimation.
const Color _kCupertinoPageTransitionBarrierColor = Color(0x18000000);

/// A mixin that replaces the entire screen with an iOS transition for a
/// [PageRoute].
///
/// The page slides in from the right and exits in reverse. The page also shifts
/// to the left in parallax when another page enters to cover it.
///
/// The page slides in from the bottom and exits in reverse with no parallax
/// effect for fullscreen dialogs.
///
/// In contrast to [CupertinoRouteTransitionMixin], the back swipe gesture stays
/// enabled when the route's [ModalRoute.popDisposition] is
/// [RoutePopDisposition.doNotPop] (e.g. due to a [PopScope] with
/// `canPop: false`). In that case the page can be dragged a bit before it snaps
/// back and the route's [ModalRoute.onPopInvokedWithResult] is called with
/// `didPop: false`.
///
/// See also:
///
///  * [PopScopeAwareCupertinoPageTransitionBuilder], which uses this mixin to
///    define a [PageTransitionsBuilder].
mixin PopScopeAwareCupertinoRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  /// Whether this route introduces a route scope in the semantics tree.
  ///
  /// Defaults to true. When true, screen readers can treat pushes and pops of
  /// this route as navigation to a new screen and announce the change to users.
  bool get includeRouteSemantics => true;

  /// A title string for this route.
  ///
  /// Used to auto-populate [CupertinoNavigationBar] and
  /// [CupertinoSliverNavigationBar]'s `middle`/`largeTitle` widgets when
  /// one is not manually supplied.
  String? get title;

  ValueNotifier<String?>? _previousTitle;

  /// The title string of the previous [PopScopeAwareCupertinoRouteTransitionMixin]
  /// route.
  ///
  /// The [ValueListenable]'s value is readable after the route is installed
  /// onto a [Navigator]. The [ValueListenable] will also notify its listeners
  /// if the value changes (such as by replacing the previous route).
  ///
  /// The [ValueListenable] itself will be null before the route is installed.
  /// Its content value will be null if the previous route has no title or
  /// does not use this mixin.
  ValueListenable<String?> get previousTitle {
    assert(
      _previousTitle != null,
      'Cannot read the previousTitle for a route that has not yet been installed',
    );
    return _previousTitle!;
  }

  @override
  void dispose() {
    _previousTitle?.dispose();
    super.dispose();
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    final String? previousTitleString =
        previousRoute is PopScopeAwareCupertinoRouteTransitionMixin
        ? previousRoute.title
        : null;
    if (_previousTitle == null) {
      _previousTitle = ValueNotifier<String?>(previousTitleString);
    } else {
      _previousTitle!.value = previousTitleString;
    }
    super.didChangePrevious(previousRoute);
  }

  /// The duration of the page transition.
  ///
  /// A relatively rigorous eyeball estimation.
  static const Duration kTransitionDuration = Duration(milliseconds: 500);

  @override
  Duration get transitionDuration => kTransitionDuration;

  @override
  Color? get barrierColor =>
      fullscreenDialog ? null : _kCupertinoPageTransitionBarrierColor;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    final bool nextRouteIsNotFullscreen =
        (nextRoute is! PageRoute<T>) || !nextRoute.fullscreenDialog;

    // If the next route has a delegated transition, then this route is able to
    // use that delegated transition to smoothly sync with the next route's
    // transition.
    final bool nextRouteHasDelegatedTransition =
        nextRoute is ModalRoute<T> && nextRoute.delegatedTransition != null;

    // Otherwise if the next route has the same route transition mixin as this
    // one, then this route will already be synced with its transition.
    return nextRouteIsNotFullscreen &&
        ((nextRoute is PopScopeAwareCupertinoRouteTransitionMixin) ||
            nextRouteHasDelegatedTransition);
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    // Suppress previous route from transitioning if this is a fullscreenDialog route.
    return previousRoute is PageRoute && !fullscreenDialog;
  }

  /// Whether a pop gesture can be started by the user.
  ///
  /// Unlike [ModalRoute.popGestureEnabled], this stays true if the route's
  /// [popDisposition] is [RoutePopDisposition.doNotPop].
  ///
  /// This should only be used between frames, not during build.
  @override
  bool get popGestureEnabled => _isPopGestureEnabled(this);

  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
    // If there's nothing to go back to, then obviously we don't support
    // the back gesture.
    if (route.isFirst) {
      return false;
    }
    // If the route wouldn't actually pop if we popped it, then the gesture
    // would be really confusing (or would skip internal routes), so disallow it.
    if (route.willHandlePopInternally) {
      return false;
    }
    // ATTENTION: Here we differ from the original implementation, which
    // disables the gesture if attempts to dismiss this route might be vetoed:
    //
    // if (route.hasScopedWillPopCallback ||
    //     route.popDisposition == RoutePopDisposition.doNotPop) {
    //   return false;
    // }
    //
    // Fullscreen dialogs aren't dismissible by back swipe.
    if (route.fullscreenDialog) {
      return false;
    }
    // If we're in an animation already, we cannot be manually swiped.
    if (!route.animation!.isCompleted) {
      return false;
    }
    // If we're being popped into, we also cannot be swiped until the pop above
    // it completes. This translates to our secondary animation being
    // dismissed.
    if (!route.secondaryAnimation!.isDismissed) {
      return false;
    }
    // If we're in a gesture already, we cannot start another.
    if (route.popGestureInProgress) {
      return false;
    }

    // Looks like a back gesture would be welcome!
    return true;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget child = buildContent(context);
    if (!includeRouteSemantics) {
      return child;
    }
    return Semantics(scopesRoute: true, explicitChildNodes: true, child: child);
  }

  // Called by _CupertinoBackGestureDetector when a pop ("back") drag start
  // gesture is detected. If the route would not pop, it returns a callback
  // invoking the route's `onPopInvokedWithResult` with didPop = false.
  static VoidCallback? _maybeGetOnPopInvokedCallback<T>(PageRoute<T> route) {
    if (route.popDisposition == RoutePopDisposition.doNotPop) {
      return () => route.onPopInvokedWithResult(false, null);
    }
    return null;
  }

  // Called by _CupertinoBackGestureDetector when a pop ("back") drag start
  // gesture is detected. The returned controller handles all of the subsequent
  // drag events.
  static _CupertinoBackGestureController<T> _startPopGesture<T>(
    PageRoute<T> route,
  ) {
    assert(_isPopGestureEnabled(route));

    return _CupertinoBackGestureController<T>(
      navigator: route.navigator!,
      getIsCurrent: () => route.isCurrent,
      getIsActive: () => route.isActive,
      controller: route.controller!, // protected access
    );
  }

  /// Returns a [CupertinoFullscreenDialogTransition] if [route] is a full
  /// screen dialog, otherwise a [CupertinoPageTransition] with a
  /// pop scope aware back gesture detector is returned.
  ///
  /// This method can be applied to any [PageRoute]. It's typically used to
  /// provide a Cupertino style horizontal transition for material widgets when
  /// the target platform is [TargetPlatform.iOS].
  ///
  /// See also:
  ///
  ///  * [PopScopeAwareCupertinoPageTransitionBuilder], which uses this method
  ///    to define a [PageTransitionsBuilder].
  static Widget buildPageTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check if the route has an animation that's currently participating
    // in a back swipe gesture.
    //
    // In the middle of a back gesture drag, let the transition be linear to
    // match finger motions.
    final bool linearTransition = route.popGestureInProgress;
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      );
    } else {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: _CupertinoBackGestureDetector<T>(
          enabledCallback: () => _isPopGestureEnabled<T>(route),
          onStartPopGesture: () => _startPopGesture<T>(route),
          getExecuteOnPopCallback: () =>
              _maybeGetOnPopInvokedCallback<T>(route),
          child: child,
        ),
      );
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// This is the widget side of [_CupertinoBackGestureController].
///
/// This widget provides a gesture recognizer which, when it determines the
/// route can be closed with a back gesture, creates the controller and
/// feeds it the input from the gesture recognizer.
///
/// If the route would not pop, the drag is cancelled once it passes
/// [_kMaxSwipeDistance] and the route's `onPopInvokedWithResult` is called.
///
/// The gesture data is converted from absolute coordinates to logical
/// coordinates by this widget.
///
/// The type `T` specifies the return type of the route with which this gesture
/// detector is associated.
class _CupertinoBackGestureDetector<T> extends StatefulWidget {
  const _CupertinoBackGestureDetector({
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.getExecuteOnPopCallback,
    required this.child,
  });

  final Widget child;

  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_CupertinoBackGestureController<T>> onStartPopGesture;

  final ValueGetter<VoidCallback?> getExecuteOnPopCallback;

  @override
  _CupertinoBackGestureDetectorState<T> createState() =>
      _CupertinoBackGestureDetectorState<T>();
}

class _CupertinoBackGestureDetectorState<T>
    extends State<_CupertinoBackGestureDetector<T>> {
  _CupertinoBackGestureController<T>? _backGestureController;

  late HorizontalDragGestureRecognizer _recognizer;

  VoidCallback? _executeOnPopCallback;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();

    // If this is disposed during a drag, call navigator.didStopUserGesture.
    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator.mounted ?? false) {
          _backGestureController?.navigator.didStopUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _executeOnPopCallback = widget.getExecuteOnPopCallback();
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);

    // ATTENTION: Here we differ from the original implementation. If the
    // route would not pop, snap it back once it is dragged past
    // _kMaxSwipeDistance and notify the route.
    final VoidCallback? executeOnPopCallback = _executeOnPopCallback;
    if (executeOnPopCallback != null &&
        details.globalPosition.dx > context.size!.width * _kMaxSwipeDistance) {
      executeOnPopCallback();
      _handleDragCancel();
    }
    _backGestureController?.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    _backGestureController?.dragEnd(
      _convertToLogical(
        details.velocity.pixelsPerSecond.dx / context.size!.width,
      ),
    );
    _backGestureController = null;
    _executeOnPopCallback = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _executeOnPopCallback = null;
    // This can be called even if start is not called, paired with the "down" event
    // that we don't consider here.
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    // For devices with notches, the drag area needs to be larger on the side
    // that has the notch.
    final double dragAreaWidth = switch (Directionality.of(context)) {
      TextDirection.rtl => MediaQuery.paddingOf(context).right,
      TextDirection.ltr => MediaQuery.paddingOf(context).left,
    };
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: max(dragAreaWidth, _kBackGestureWidth),
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// A controller for an iOS-style back gesture.
///
/// This is created by a [PopScopeAwareCupertinoRouteTransitionMixin] route in
/// response from a gesture caught by a [_CupertinoBackGestureDetector] widget,
/// which then also feeds it input from the gesture. It controls the animation
/// controller owned by the route, based on the input provided by the gesture
/// detector.
///
/// This class works entirely in logical coordinates (0.0 is new page dismissed,
/// 1.0 is new page on top).
///
/// The type `T` specifies the return type of the route with which this gesture
/// detector controller is associated.
class _CupertinoBackGestureController<T> {
  /// Creates a controller for an iOS-style back gesture.
  _CupertinoBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;

  /// The drag gesture has changed by [delta]. The total range of the drag
  /// should be 0.0 to 1.0.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// The drag gesture has ended with a horizontal motion of [velocity] as a
  /// fraction of screen width per second.
  void dragEnd(double velocity) {
    // Fling in the appropriate direction.
    //
    // This curve has been determined through rigorously eyeballing native iOS
    // animations.
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      // If the page has already been navigated away from, then the animation
      // direction depends on whether or not it's still in the navigation stack,
      // regardless of velocity or drag position. For example, if a route is
      // being slowly dragged back by just a few pixels, but then a programmatic
      // pop occurs, the route should still be animated off the screen.
      // See https://github.com/flutter/flutter/issues/141268.
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      // If the user releases the page before mid screen with sufficient velocity,
      // or after mid screen, we should animate the page out. Otherwise, the page
      // should be animated back in.
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: _kDroppedSwipePageAnimationDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        // This route is destined to pop at this point. Reuse navigator's pop.
        navigator.pop();
      }

      // The popping may have finished inline if already at the target destination.
      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: _kDroppedSwipePageAnimationDuration,
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since CupertinoPageTransition
      // depends on userGestureInProgress.
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
