import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pop_scope_aware_cupertino_route/pop_scope_aware_cupertino_route.dart';

class _TestRoute<T> extends PageRoute<T>
    with PopScopeAwareCupertinoRouteTransitionMixin<T> {
  _TestRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildContent(BuildContext context) => builder(context);
}

class _Home extends StatelessWidget {
  const _Home({required this.secondPage, required this.onResult});

  final Widget secondPage;
  final ValueChanged<Object?> onResult;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: CupertinoButton(
          onPressed: () async {
            final result = await Navigator.of(context)
                .push(_TestRoute<Object?>(builder: (_) => secondPage));
            onResult(result);
          },
          child: const Text('push'),
        ),
      ),
    );
  }
}

Future<void> _swipeBack(WidgetTester tester, {required double distance}) async {
  final gesture = await tester.startGesture(const Offset(5, 300));
  const steps = 20;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(distance / steps, 0));
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('swipe back on a route with canPop: false invokes the callback '
      'and keeps the route', (tester) async {
    final invocations = <bool>[];
    var popped = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: _Home(
          onResult: (_) => popped = true,
          secondPage: PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) => invocations.add(didPop),
            child: const CupertinoPageScaffold(child: Text('second')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);

    await _swipeBack(tester, distance: 600);

    expect(invocations, <bool>[false]);
    expect(popped, isFalse);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('push'), findsNothing);
    expect(tester.getTopLeft(find.text('second')).dx, 0);
  });

  testWidgets('route with canPop: false can be dragged a bit before snapping '
      'back', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: _Home(
          onResult: (_) {},
          secondPage: const PopScope<Object?>(
            canPop: false,
            child: CupertinoPageScaffold(child: Text('second')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('second')).dx, greaterThan(0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('second')).dx, 0);
  });

  testWidgets('swipe back on a route with canPop: true pops the route', (
    tester,
  ) async {
    final invocations = <bool>[];
    var popped = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: _Home(
          onResult: (_) => popped = true,
          secondPage: PopScope<Object?>(
            onPopInvokedWithResult: (didPop, _) => invocations.add(didPop),
            child: const CupertinoPageScaffold(child: Text('second')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    await _swipeBack(tester, distance: 600);

    expect(invocations, <bool>[true]);
    expect(popped, isTrue);
    expect(find.text('second'), findsNothing);
    expect(find.text('push'), findsOneWidget);
  });
}
