import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/ai_content.dart';
import '../../domain/entities/learning_state.dart';
import '../../domain/entities/review_entry.dart';
import '../../domain/entities/word_detail.dart';
import '../bloc/word_detail_bloc.dart';
import '../bloc/word_detail_event.dart';
import '../bloc/word_detail_state.dart';

enum _WordDetailAction { regenerate, delete }

class WordDetailPage extends StatelessWidget {
  const WordDetailPage({super.key});

  Future<void> _confirmRegenerate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate AI content?'),
        content: const Text(
          'Lexi will ask the AI for fresh meanings and examples. '
          'This can take a moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmRegenerateButton'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<WordDetailBloc>().add(const RegenerateWordDetailAi());
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this word?'),
        content: const Text(
          'The word will be removed from your library. '
          'This cannot be undone in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteButton'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<WordDetailBloc>().add(const DeleteWordDetail());
    }
  }

  void _handleAction(BuildContext context, _WordDetailAction action) {
    switch (action) {
      case _WordDetailAction.regenerate:
        _confirmRegenerate(context);
        return;
      case _WordDetailAction.delete:
        _confirmDelete(context);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WordDetailBloc>().state;
    final detail = state.detail;

    return BlocListener<WordDetailBloc, WordDetailState>(
      listenWhen: (previous, current) =>
          current.status == WordDetailStatus.deleted &&
          previous.status != WordDetailStatus.deleted,
      listener: (context, state) {
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(detail?.summary.word ?? 'Word detail'),
          actions: [
            if (detail != null && state.status != WordDetailStatus.deleted)
              PopupMenuButton<_WordDetailAction>(
                key: const Key('wordDetailMenuButton'),
                enabled: !state.isBusy,
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _WordDetailAction.regenerate,
                    child: Text('Regenerate AI'),
                  ),
                  PopupMenuItem(
                    value: _WordDetailAction.delete,
                    child: Text('Delete word'),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: switch (state.status) {
            WordDetailStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            WordDetailStatus.error => _DetailError(
              failure: state.failure,
              onRetry: () {
                context.read<WordDetailBloc>().add(const LoadWordDetail());
              },
            ),
            WordDetailStatus.notFound => _NotFound(
              onBack: () => Navigator.of(context).pop(),
            ),
            WordDetailStatus.deleted => const SizedBox.shrink(),
            WordDetailStatus.ready || WordDetailStatus.pending =>
              detail == null
                  ? const Center(child: CircularProgressIndicator())
                  : _DetailContent(
                      detail: detail,
                      state: state,
                      onRetryAI: () {
                        context.read<WordDetailBloc>().add(
                          const LoadWordDetail(),
                        );
                      },
                      onRegenerate: () => _confirmRegenerate(context),
                    ),
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.state,
    required this.onRetryAI,
    required this.onRegenerate,
  });

  final WordDetail detail;
  final WordDetailState state;
  final VoidCallback onRetryAI;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final content = detail.aiContent;
    final hasSource =
        summary.sourceContext != null ||
        summary.sourceTitle != null ||
        summary.sourceUrl != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        if (state.isBusy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        Text(
          summary.word,
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (summary.pronunciation != null) ...[
          const SizedBox(height: 6),
          Text(
            summary.pronunciation!,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (summary.partOfSpeech != null)
              _Pill(label: summary.partOfSpeech!),
            _Pill(label: 'Difficulty ${summary.difficulty}/5'),
            _Pill(
              label: summary.learningState?.status.label ?? 'New',
              emphasized: true,
            ),
            _Pill(label: detail.aiReady ? 'AI ready' : 'AI pending'),
          ],
        ),
        const SizedBox(height: 24),
        _LearningCard(learningState: summary.learningState),
        if (state.actionFailure != null) ...[
          const SizedBox(height: 16),
          _InlineError(failure: state.actionFailure!),
        ],
        if (!detail.aiReady) ...[
          const SizedBox(height: 16),
          _PendingAiCard(
            exhausted: state.pollExhausted,
            isRegenerating: state.isRegenerating,
            onRetry: onRetryAI,
            onRegenerate: onRegenerate,
          ),
        ],
        if (content != null && content.meanings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Meanings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < content.meanings.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == content.meanings.length - 1 ? 0 : 12,
                    ),
                    child: _MeaningRow(meaning: content.meanings[i]),
                  ),
              ],
            ),
          ),
        ],
        if (content != null && content.examples.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Examples',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < content.examples.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == content.examples.length - 1 ? 0 : 14,
                    ),
                    child: _ExampleRow(example: content.examples[i]),
                  ),
              ],
            ),
          ),
        ],
        if (content != null &&
            (content.synonyms.isNotEmpty || content.antonyms.isNotEmpty)) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Related words',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.synonyms.isNotEmpty)
                  _WordChipGroup(label: 'Synonyms', words: content.synonyms),
                if (content.synonyms.isNotEmpty && content.antonyms.isNotEmpty)
                  const SizedBox(height: 14),
                if (content.antonyms.isNotEmpty)
                  _WordChipGroup(label: 'Antonyms', words: content.antonyms),
              ],
            ),
          ),
        ],
        if (hasSource) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Source',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.sourceTitle != null) ...[
                  Text(
                    summary.sourceTitle!,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (summary.sourceContext != null) ...[
                  Text(
                    summary.sourceContext!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (summary.sourceUrl != null)
                  SelectableText(
                    summary.sourceUrl!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _ReviewsCard(reviews: detail.reviews),
      ],
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.learningState});

  final LearningState? learningState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = learningState;
    final score = state?.knowledgeScore ?? 0;
    final percent = (score * 100).round();

    return _SectionCard(
      title: 'Learning state',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state?.status.label ?? 'New',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state?.nextReviewAt == null
                ? 'Review schedule: not scheduled yet'
                : 'Next review: ${_formatDate(state!.nextReviewAt)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingAiCard extends StatelessWidget {
  const _PendingAiCard({
    required this.exhausted,
    required this.isRegenerating,
    required this.onRetry,
    required this.onRegenerate,
  });

  final bool exhausted;
  final bool isRegenerating;
  final VoidCallback onRetry;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exhausted
                      ? 'AI content is still pending'
                      : 'Generating AI content',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exhausted
                ? 'The automatic checks have stopped. Retry or regenerate '
                      'the content manually.'
                : 'Lexi is generating meanings and examples. '
                      'This page checks automatically.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('wordDetailCheckAgainButton'),
                onPressed: isRegenerating ? null : onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Check again'),
              ),
              OutlinedButton.icon(
                key: const Key('wordDetailRegenerateButton'),
                onPressed: isRegenerating ? null : onRegenerate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Regenerate AI'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.reviews});

  final List<ReviewEntry> reviews;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      title: 'Recent reviews',
      child: reviews.isEmpty
          ? Text(
              'No reviews yet.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < reviews.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == reviews.length - 1 ? 0 : 12,
                    ),
                    child: _ReviewRow(review: reviews[i]),
                  ),
              ],
            ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final ReviewEntry review;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resultColor = switch (review.result) {
      ReviewResult.correct => colorScheme.primary,
      ReviewResult.incorrect => colorScheme.error,
      ReviewResult.partial => colorScheme.tertiary,
      ReviewResult.skipped => colorScheme.onSurfaceVariant,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: resultColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${review.result.label} · ${_humanize(review.exerciseType)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (review.createdAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDate(review.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MeaningRow extends StatelessWidget {
  const _MeaningRow({required this.meaning});

  final WordMeaning meaning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          meaning.isPrimary ? Icons.star : Icons.circle,
          size: meaning.isPrimary ? 18 : 10,
          color: meaning.isPrimary
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            meaning.meaning,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: meaning.isPrimary ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.example});

  final WordExample example;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(example.sentence, style: textTheme.bodyMedium),
        if (example.context != null) ...[
          const SizedBox(height: 4),
          Text(
            example.context!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _WordChipGroup extends StatelessWidget {
  const _WordChipGroup({required this.label, required this.words});

  final String label;
  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in words)
              Chip(label: Text(word), visualDensity: VisualDensity.compact),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failure.message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.failure, required this.onRetry});

  final AppFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              failure?.message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('wordDetailRetryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'This word was not found.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('wordDetailBackButton'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to library'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return 'Not scheduled';
  }
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _humanize(String value) {
  final words = value
      .toLowerCase()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}');
  return words.join(' ');
}
