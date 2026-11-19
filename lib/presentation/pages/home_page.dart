import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lexi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Your vocabulary, learned.',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Capture the words you meet and turn them into lasting knowledge.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('homeAddWordsButton'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addWord);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add words'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
