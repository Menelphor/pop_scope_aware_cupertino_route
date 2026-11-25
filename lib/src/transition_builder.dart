import 'package:cupertino_ui/cupertino_ui.dart';

import 'route.dart';

/// A [PageTransitionsBuilder] that matches the iOS page transition and keeps
/// the back swipe gesture enabled for routes that cannot be popped, e.g. due
/// to a [PopScope] with `canPop: false`.
///
/// See also:
///
///  * [PopScopeAwareCupertinoRouteTransitionMixin], which implements the
///    transition and the pop scope aware back gesture.
class PopScopeAwareCupertinoPageTransitionBuilder
    extends PageTransitionsBuilder {
  /// Constructs a page transition animation that matches the iOS transition.
  const PopScopeAwareCupertinoPageTransitionBuilder();

  @override
  Duration get transitionDuration =>
      PopScopeAwareCupertinoRouteTransitionMixin.kTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return PopScopeAwareCupertinoRouteTransitionMixin.buildPageTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
