import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_entry.dart';
import '../../domain/entities/review_exercise.dart';
import '../../domain/entities/review_submission_result.dart';
import '../bloc/review_session_bloc.dart';
import '../bloc/review_session_event.dart';
import '../bloc/review_session_state.dart';

class ReviewSessionPage extends StatefulWidget {
  const ReviewSessionPage({super.key});

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  Future<void> _close() async {
    final state = context.read<ReviewSessionBloc>().state;
    final shouldReload =
        state.status == ReviewSessionStatus.completed ||
        state.status == ReviewSessionStatus.empty;

    if (!state.isActive && state.failureStep == null) {
      Navigator.of(context).pop(shouldReload);
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this session?'),
        content: const Text(
          'Your unanswered questions will stay in today\'s queue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep reviewing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReviewSessionBloc>().state;
    final canPop = !state.isActive && state.failureStep == null;

    return PopScope<void>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const Key('reviewCloseButton'),
            tooltip: 'Close review',
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
          title: const Text('Review session'),
        ),
        body: switch (state.status) {
          ReviewSessionStatus.idle ||
          ReviewSessionStatus.loading => const _SessionLoading(),
          ReviewSessionStatus.empty => _SessionEmpty(
            pendingAiCount: state.pendingAiCount,
            onClose: _close,
          ),
          ReviewSessionStatus.completed => _SessionComplete(
            state: state,
            onClose: _close,
          ),
          ReviewSessionStatus.failure => _SessionFailure(
            failure: state.failure,
            onRetry: () {
              context.read<ReviewSessionBloc>().add(const RetryReviewSession());
            },
          ),
          ReviewSessionStatus.answering ||
          ReviewSessionStatus.submitting ||
          ReviewSessionStatus.feedback => _ExerciseView(
            state: state,
            onSelect: (answer) {
              context.read<ReviewSessionBloc>().add(SelectReviewAnswer(answer));
            },
            onSubmit: () {
              context.read<ReviewSessionBloc>().add(const SubmitReviewAnswer());
            },
            onSkip: () {
              context.read<ReviewSessionBloc>().add(const SkipReviewQuestion());
            },
            onContinue: () {
              context.read<ReviewSessionBloc>().add(
                const ContinueReviewSession(),
              );
            },
          ),
        },
      ),
    );
  }
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparing today\'s review...'),
        ],
      ),
    );
  }
}

class _ExerciseView extends StatelessWidget {
  const _ExerciseView({
    required this.state,
    required this.onSelect,
    required this.onSubmit,
    required this.onSkip,
    required this.onContinue,
  });

  final ReviewSessionState state;
  final ValueChanged<String> onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = state.exercise;
    final item = state.currentItem;

    if (exercise == null || item == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAnswering = state.status == ReviewSessionStatus.answering;
    final isSubmitting = state.status == ReviewSessionStatus.submitting;
    final isFeedback = state.status == ReviewSessionStatus.feedback;
    final result = state.result;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            Text(
              'Question ${state.currentIndex + 1} of ${state.totalInSession}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${(state.progress * 100).round()}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: state.progress),
        const SizedBox(height: 28),
        Text(
          item.word,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          exercise.question,
          key: const Key('reviewQuestionText'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < exercise.options.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionCard(
              key: Key('reviewOption-$index'),
              text: exercise.options[index],
              selected: state.selectedAnswer == exercise.options[index],
              enabled: isAnswering,
              isCorrect:
                  isFeedback &&
                  result?.review.correctAnswer == exercise.options[index],
              isIncorrect:
                  isFeedback &&
                  state.selectedAnswer == exercise.options[index] &&
                  result?.review.result != ReviewResult.correct,
              onTap: () => onSelect(exercise.options[index]),
            ),
          ),
        const SizedBox(height: 12),
        if (isFeedback && result != null)
          _FeedbackCard(result: result, exercise: exercise),
        if (isFeedback) const SizedBox(height: 16),
        if (isFeedback)
          FilledButton(
            key: const Key('reviewContinueButton'),
            onPressed: onContinue,
            child: Text(state.isLastQuestion ? 'Finish' : 'Continue'),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('reviewSkipButton'),
                  onPressed: isAnswering ? onSkip : null,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const Key('reviewSubmitButton'),
                  onPressed: isAnswering && state.canSubmit ? onSubmit : null,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.text,
    required this.selected,
    required this.enabled,
    required this.isCorrect,
    required this.isIncorrect,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool enabled;
  final bool isCorrect;
  final bool isIncorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderColor = isCorrect
        ? colorScheme.primary
        : isIncorrect
        ? colorScheme.error
        : selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final backgroundColor = isCorrect
        ? colorScheme.primaryContainer
        : isIncorrect
        ? colorScheme.errorContainer
        : selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : colorScheme.surface;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: borderColor,
          width: selected || isCorrect || isIncorrect ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : isIncorrect
                    ? Icons.cancel
                    : selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isCorrect
                    ? colorScheme.primary
                    : isIncorrect
                    ? colorScheme.error
                    : selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.result, required this.exercise});

  final ReviewSubmissionResult result;
  final ReviewExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCorrect = result.review.result == ReviewResult.correct;
    final isSkipped = result.review.result == ReviewResult.skipped;
    final icon = isCorrect
        ? Icons.check_circle
        : isSkipped
        ? Icons.skip_next
        : Icons.cancel;
    final title = isCorrect
        ? 'Correct'
        : isSkipped
        ? 'Skipped'
        : 'Not quite';
    final color = isCorrect
        ? colorScheme.primary
        : isSkipped
        ? colorScheme.onSurfaceVariant
        : colorScheme.error;
    final explanation = exercise.explanation;

    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Correct answer: ${exercise.correctAnswer}',
              style: theme.textTheme.bodyMedium,
            ),
            if (explanation != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                explanation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionComplete extends StatelessWidget {
  const _SessionComplete({required this.state, required this.onClose});

  final ReviewSessionState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = state.answeredCount == 0
        ? 0
        : (state.correctCount / state.answeredCount * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      children: [
        Icon(
          Icons.celebration_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Session complete',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You reviewed ${state.answeredCount} '
          '${state.answeredCount == 1 ? 'word' : 'words'}.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'Correct',
                value: state.correctCount,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryStat(
                label: 'Incorrect',
                value: state.incorrectCount,
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'Skipped',
                value: state.skippedCount,
                icon: Icons.skip_next_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryStat(
                label: 'Accuracy',
                value: accuracy,
                suffix: '%',
                icon: Icons.percent,
              ),
            ),
          ],
        ),
        if (state.pendingAiCount > 0) ...[
          const SizedBox(height: 16),
          Text(
            '${state.pendingAiCount} '
            '${state.pendingAiCount == 1 ? 'word was' : 'words were'} '
            'skipped because AI content is still pending.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          key: const Key('reviewFinishButton'),
          onPressed: onClose,
          child: const Text('Back to Review'),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix = '',
  });

  final String label;
  final int value;
  final IconData icon;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              '$value$suffix',
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

class _SessionEmpty extends StatelessWidget {
  const _SessionEmpty({required this.pendingAiCount, required this.onClose});

  final int pendingAiCount;
  final VoidCallback onClose;

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
              pendingAiCount > 0
                  ? 'Some words are still waiting for AI content.'
                  : 'Nothing is due for review right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const Key('reviewEmptyCloseButton'),
              onPressed: onClose,
              child: const Text('Back to Review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionFailure extends StatelessWidget {
  const _SessionFailure({required this.failure, required this.onRetry});

  final AppFailure? failure;
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
              failure?.message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton(
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
