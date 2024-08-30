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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<String?> _goToSecondScreen(BuildContext context) =>
      Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const SecondScreen()));

  String? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Result: $result'),
            ElevatedButton(
              onPressed: () async {
                final newResult = await _goToSecondScreen(context);
                setState(() {
                  result = newResult;
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Text('Go to second screen'),
              ),
            ),
          ],
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

  _onWillPop(bool popAllowed, result) async {
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
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop('popped in dialog'),
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
      onPopInvokedWithResult: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Second Screen')),
        body: Column(
          children: [
            SwitchListTile(
              title: const Text('Back Navigation Enabled'),
              value: _popAllowed,
              onChanged: _updateChanges,
            ),
            ListTile(
              title: const Text('pop till home with result'),
              onTap: () => Navigator.of(context).pop('popped till home'),
            )
          ],
        ),
      ),
    );
  }
}
