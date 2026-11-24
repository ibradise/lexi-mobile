import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/dashboard_data.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onAddWords,
    required this.onStartReview,
    required this.onOpenWord,
  });

  final VoidCallback onAddWords;
  final VoidCallback onStartReview;
  final ValueChanged<WeakestWord> onOpenWord;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            key: const Key('dashboardRefreshButton'),
            tooltip: 'Refresh dashboard',
            onPressed: state.isLoading
                ? null
                : () {
                    context.read<DashboardBloc>().add(const LoadDashboard());
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          DashboardState(failure: final failure?) => _DashboardError(
            failure: failure,
            onRetry: () {
              context.read<DashboardBloc>().add(const LoadDashboard());
            },
          ),
          DashboardState(data: null) =>
            state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          DashboardState(data: final value?) when value.isLibraryEmpty =>
            _DashboardEmpty(
              onAddWords: onAddWords,
              onStartReview: onStartReview,
              data: value,
            ),
          DashboardState(data: final value?) => _DashboardContent(
            data: value,
            onStartReview: onStartReview,
            onOpenWord: onOpenWord,
          ),
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.onStartReview,
    required this.onOpenWord,
  });

  final DashboardData data;
  final VoidCallback onStartReview;
  final ValueChanged<WeakestWord> onOpenWord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = data.todayReview;
    final stats = data.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text(
          'Your vocabulary, learned.',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Keep the streak going with a short review session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Today's review",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TodayStat(
                      key: const Key('dashboardDueCount'),
                      label: 'Due',
                      value: today.due,
                      emphasized: true,
                    ),
                    const SizedBox(width: 18),
                    _TodayStat(
                      key: const Key('dashboardNewCount'),
                      label: 'New',
                      value: today.newWords,
                    ),
                    const SizedBox(width: 18),
                    _TodayStat(
                      key: const Key('dashboardAttentionCount'),
                      label: 'Attention',
                      value: today.needAttention,
                    ),
                    const SizedBox(width: 18),
                    _TodayStat(
                      key: const Key('dashboardBecomingStrongCount'),
                      label: 'Growing',
                      value: today.becomingStrong,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (today.due == 0)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You're all caught up for today.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('dashboardStartButton'),
                      onPressed: onStartReview,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'Start review (${today.due} '
                        '${today.due == 1 ? 'word' : 'words'})',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProgressCard(
                label: 'Words',
                value: '${stats.totalWords}',
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProgressCard(
                label: 'Reviewed today',
                value: '${stats.reviewsToday}',
                icon: Icons.fact_check_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ProgressCard(
                label: '7-day accuracy',
                value: '${(stats.accuracyLast7Days * 100).round()}%',
                icon: Icons.track_changes,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProgressCard(
                label: 'Streak',
                value:
                    '${stats.currentStreak} '
                    '${stats.currentStreak == 1 ? 'day' : 'days'}',
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning mix',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: 'New', count: stats.newWords),
                    _StatusPill(label: 'Learning', count: stats.learning),
                    _StatusPill(label: 'Familiar', count: stats.familiar),
                    _StatusPill(label: 'Strong', count: stats.strong),
                    _StatusPill(label: 'Mastered', count: stats.mastered),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Needs attention',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'The words with the lowest knowledge scores right now.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (data.weakestWords.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No weak words right now. Keep reviewing to stay sharp.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (final word in data.weakestWords)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WeakestWordCard(
                key: Key('dashboardWeakest-${word.wordId}'),
                word: word,
                onTap: () => onOpenWord(word),
              ),
            ),
      ],
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({
    required this.onAddWords,
    required this.onStartReview,
    required this.data,
  });

  final VoidCallback onAddWords;
  final VoidCallback onStartReview;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 96),
      children: [
        Icon(Icons.auto_stories_outlined, size: 48, color: colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Your vocabulary, learned.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Capture the words you meet and turn them into lasting knowledge.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No words yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add your first word or paste a list to start building '
                  'your daily review queue.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('dashboardEmptyAddButton'),
                  onPressed: onAddWords,
                  icon: const Icon(Icons.add),
                  label: const Text('Add words'),
                ),
              ],
            ),
          ),
        ),
        if (data.todayReview.due > 0) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('dashboardStartButton'),
            onPressed: onStartReview,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start review'),
          ),
        ],
      ],
    );
  }
}

class _TodayStat extends StatelessWidget {
  const _TodayStat({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasized
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $count',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _WeakestWordCard extends StatelessWidget {
  const _WeakestWordCard({super.key, required this.word, required this.onTap});

  final WeakestWord word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = (word.knowledgeScore * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Knowledge score $score%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.failure, required this.onRetry});

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
              key: const Key('dashboardRetryButton'),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
