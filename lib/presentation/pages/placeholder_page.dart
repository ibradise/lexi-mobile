import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lexi')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lexi', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Your vocabulary, learned.', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
