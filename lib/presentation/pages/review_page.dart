import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_queue.dart';
import '../bloc/review_queue_bloc.dart';
import '../bloc/review_queue_event.dart';
import '../bloc/review_queue_state.dart';
import '../navigation/app_routes.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  Future<void> _startReview(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.reviewSession);
    if (context.mounted) {
      context.read<ReviewQueueBloc>().add(const LoadReviewQueue());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReviewQueueBloc>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: SafeArea(
        child: switch (state) {
          ReviewQueueState(failure: final failure?) => _ReviewError(
            failure: failure,
            onRetry: () {
              context.read<ReviewQueueBloc>().add(const LoadReviewQueue());
            },
          ),
          ReviewQueueState(isLoading: true) => const Center(
            child: CircularProgressIndicator(),
          ),
          ReviewQueueState(queue: null) => const SizedBox.shrink(),
          ReviewQueueState(queue: final value?) when value.isEmpty =>
            const _EmptyReview(),
          ReviewQueueState(queue: final value?) => _ReviewQueueContent(
            queue: value,
            onStartReview: () => _startReview(context),
          ),
        },
      ),
    );
  }
}

class _ReviewQueueContent extends StatelessWidget {
  const _ReviewQueueContent({required this.queue, required this.onStartReview});

  final ReviewQueue queue;
  final VoidCallback onStartReview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pendingCount = queue.queue.where((item) => !item.aiReady).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text(
          "Today's review",
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                key: const Key('reviewDueCount'),
                label: 'Due',
                value: queue.totalDue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountCard(
                key: const Key('reviewNewCount'),
                label: 'New',
                value: queue.newWords,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountCard(
                key: const Key('reviewQueueCount'),
                label: 'Reviews',
                value: queue.reviewWords,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const Key('reviewStartButton'),
          onPressed: onStartReview,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start review'),
        ),
        if (pendingCount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pendingCount ${pendingCount == 1 ? 'word is' : 'words are'} '
                    'waiting for AI content and will be skipped.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Queue',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (queue.queue.isEmpty)
          const Text('Nothing is due right now.')
        else
          for (final item in queue.queue)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QueueItemCard(item: item),
            ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueItemCard extends StatelessWidget {
  const _QueueItemCard({required this.item});

  final ReviewQueueItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.word,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(item.status.label),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text(item.aiReady ? 'AI ready' : 'AI pending'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              item.aiReady ? Icons.chevron_right : Icons.hourglass_empty,
              color: item.aiReady
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Words appear here when they are due for review.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('reviewRetryButton'),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
