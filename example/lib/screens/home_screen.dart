import 'package:flutter/material.dart';

import 'second_screen.dart';

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
