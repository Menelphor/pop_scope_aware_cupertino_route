import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
