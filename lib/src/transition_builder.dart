import 'package:flutter/material.dart';
import 'package:pop_scope_aware_cupertino_route/src/route.dart';

class PopScopeAwareCupertinoPageTransitionBuilder
    extends PageTransitionsBuilder {
  const PopScopeAwareCupertinoPageTransitionBuilder();

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
