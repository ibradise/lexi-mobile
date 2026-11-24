import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_entry.dart';
import '../../domain/entities/review_history_item.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/review_history_bloc.dart';
import '../bloc/review_history_event.dart';
import '../bloc/review_history_state.dart';
import '../navigation/app_routes.dart';

class ReviewHistoryPage extends StatelessWidget {
  const ReviewHistoryPage({super.key});

  Future<void> _openWord(BuildContext context, String wordId) async {
    final deleted = await Navigator.pushNamed(
      context,
      AppRoutes.wordDetail,
      arguments: wordId,
    );
    if (!context.mounted) {
      return;
    }
    context.read<ReviewHistoryBloc>().add(const LoadReviewHistory());
    if (deleted == true) {
      context.read<LibraryBloc>().add(const LoadLibrary());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReviewHistoryBloc>().state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            key: const Key('historyRefreshButton'),
            tooltip: 'Refresh history',
            onPressed: state.isLoading
                ? null
                : () {
                    context.read<ReviewHistoryBloc>().add(
                      const LoadReviewHistory(),
                    );
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          ReviewHistoryState(failure: final failure?) => _HistoryError(
            failure: failure,
            onRetry: () {
              context.read<ReviewHistoryBloc>().add(const LoadReviewHistory());
            },
          ),
          ReviewHistoryState(isLoading: true, items: []) => const Center(
            child: CircularProgressIndicator(),
          ),
          ReviewHistoryState(isEmpty: true) => const _HistoryEmpty(),
          _ => _HistoryContent(
            state: state,
            onOpenWord: (wordId) => _openWord(context, wordId),
            onLoadMore: () {
              context.read<ReviewHistoryBloc>().add(
                const LoadMoreReviewHistory(),
              );
            },
          ),
        },
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.state,
    required this.onOpenWord,
    required this.onLoadMore,
  });

  final ReviewHistoryState state;
  final ValueChanged<String> onOpenWord;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text(
          'Review history',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          state.total == 1 ? '1 review' : '${state.total} reviews',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        for (final item in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoryItemCard(
              key: Key('historyItem-${item.id}'),
              item: item,
              onTap: () => onOpenWord(item.wordId),
            ),
          ),
        if (state.loadMoreFailure != null) ...[
          Text(
            state.loadMoreFailure!.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (state.hasMore)
          OutlinedButton(
            key: const Key('historyLoadMoreButton'),
            onPressed: state.isLoadingMore ? null : onLoadMore,
            child: state.isLoadingMore
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    state.loadMoreFailure == null ? 'Load more' : 'Try again',
                  ),
          ),
      ],
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({super.key, required this.item, required this.onTap});

  final ReviewHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _resultColor(item.result, colorScheme);
    final details = <String>[
      _humanize(item.exerciseType),
      if (item.createdAt != null) _formatDateTime(item.createdAt!),
      if (item.responseTimeMs != null)
        '${(item.responseTimeMs! / 1000).toStringAsFixed(1)}s',
      if (item.hintUsed) 'Hint used',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_resultIcon(item.result), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.word,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.result.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

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
              Icons.history_toggle_off,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a review session and your answers will appear here.',
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

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.failure, required this.onRetry});

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
              key: const Key('historyRetryButton'),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _resultColor(ReviewResult result, ColorScheme colorScheme) {
  return switch (result) {
    ReviewResult.correct => colorScheme.primary,
    ReviewResult.incorrect => colorScheme.error,
    ReviewResult.partial => colorScheme.tertiary,
    ReviewResult.skipped => colorScheme.onSurfaceVariant,
  };
}

IconData _resultIcon(ReviewResult result) {
  return switch (result) {
    ReviewResult.correct => Icons.check_circle,
    ReviewResult.incorrect => Icons.cancel,
    ReviewResult.partial => Icons.change_circle_outlined,
    ReviewResult.skipped => Icons.skip_next,
  };
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _humanize(String value) {
  final words = value
      .toLowerCase()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}');
  return words.join(' ');
}
