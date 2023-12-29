import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pop_scope_aware_cupertino_route/pop_scope_aware_cupertino_route.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: PopScopeAwareCupertinoPageTransitionBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goToSecondScreen(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const SecondScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _goToSecondScreen(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Text('Go to second screen'),
          ),
        ),
      ),
    );
  }
}

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  bool _popAllowed = false;

  _onWillPop(bool popAllowed) async {
    if (!popAllowed) {
      showAdaptiveDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog.adaptive(
          content: const Text('Back navigation is disabled.'),
          actions: [
            adaptiveAction(
              context: context,
              child: const Text('pop till home'),
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst,
              ),
            ),
            adaptiveAction(
              context: context,
              child: const Text('OK'),
              onPressed: Navigator.of(context).pop,
            ),
          ],
        ),
      );
    }
  }

  Widget adaptiveAction({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return TextButton(onPressed: onPressed, child: child);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoDialogAction(onPressed: onPressed, child: child);
    }
  }

  void _updateChanges(bool value) => setState(() => _popAllowed = value);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _popAllowed,
      onPopInvoked: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Second Screen')),
        body: Center(
          child: SwitchListTile(
            title: const Text('Back Navigation Enabled'),
            value: _popAllowed,
            onChanged: _updateChanges,
          ),
        ),
      ),
    );
  }
}
