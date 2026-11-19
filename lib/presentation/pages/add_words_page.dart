import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/add_word_params.dart';
import '../../domain/entities/bulk_add_result.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../bloc/add_word_bloc.dart';
import '../bloc/add_word_event.dart';
import '../bloc/add_word_state.dart';

enum AddWordMode { single, bulk }

class AddWordsPage extends StatefulWidget {
  const AddWordsPage({super.key});

  @override
  State<AddWordsPage> createState() => _AddWordsPageState();
}

class _AddWordsPageState extends State<AddWordsPage> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _contextController = TextEditingController();
  final _sourceTitleController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final _bulkController = TextEditingController();

  AddWordMode _mode = AddWordMode.single;

  @override
  void dispose() {
    _wordController.dispose();
    _contextController.dispose();
    _sourceTitleController.dispose();
    _sourceUrlController.dispose();
    _bulkController.dispose();
    super.dispose();
  }

  void _setMode(AddWordMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() => _mode = mode);
    context.read<AddWordBloc>().add(const ResetAddWordFlow());
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_mode == AddWordMode.single) {
      context.read<AddWordBloc>().add(
        SubmitSingleWord(
          AddWordParams(
            word: _wordController.text,
            context: _contextController.text,
            sourceTitle: _sourceTitleController.text,
            sourceUrl: _sourceUrlController.text,
          ),
        ),
      );
      return;
    }

    context.read<AddWordBloc>().add(SubmitBulkWords(_bulkController.text));
  }

  void _startAnother() {
    _wordController.clear();
    _contextController.clear();
    _sourceTitleController.clear();
    _sourceUrlController.clear();
    _bulkController.clear();
    _formKey.currentState?.reset();

    context.read<AddWordBloc>().add(const ResetAddWordFlow());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddWordBloc>().state;
    final isSubmitting = state is AddWordSubmitting;
    final failure = state is AddWordFailure ? state.failure : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add words')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (state is AddWordSingleSuccess)
              _SingleSuccessCard(word: state.word, onAddAnother: _startAnother)
            else if (state is AddWordBulkSuccess)
              _BulkSuccessCard(
                result: state.result,
                onAddAnother: _startAnother,
              )
            else ...[
              _PageIntro(mode: _mode),
              const SizedBox(height: 20),
              SegmentedButton<AddWordMode>(
                segments: const [
                  ButtonSegment(
                    value: AddWordMode.single,
                    label: Text('One word'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: AddWordMode.bulk,
                    label: Text('Bulk paste'),
                    icon: Icon(Icons.content_paste_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: isSubmitting
                    ? null
                    : (selection) => _setMode(selection.first),
              ),
              if (failure != null) ...[
                const SizedBox(height: 20),
                _FailureCard(failure: failure, onRetry: _submit),
              ],
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: _mode == AddWordMode.single
                    ? _buildSingleForm(isSubmitting)
                    : _buildBulkForm(isSubmitting),
              ),
              const SizedBox(height: 24),
              _SubmitButton(
                isSubmitting: isSubmitting,
                isBulk: _mode == AddWordMode.bulk,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleForm(bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('wordField'),
          controller: _wordController,
          enabled: !isSubmitting,
          maxLength: 100,
          validator: _validateWord,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Word',
            hintText: 'e.g. lexicon',
            prefixIcon: Icon(Icons.text_fields),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('contextField'),
          controller: _contextController,
          enabled: !isSubmitting,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Context (optional)',
            hintText: 'The sentence where you found it',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('sourceTitleField'),
          controller: _sourceTitleController,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Source title (optional)',
            hintText: 'Article or book title',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('sourceUrlField'),
          controller: _sourceUrlController,
          enabled: !isSubmitting,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Source URL (optional)',
            hintText: 'https://example.com/article',
          ),
        ),
      ],
    );
  }

  Widget _buildBulkForm(bool isSubmitting) {
    return TextFormField(
      key: const Key('bulkField'),
      controller: _bulkController,
      enabled: !isSubmitting,
      minLines: 8,
      maxLines: 14,
      validator: _validateBulk,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        labelText: 'Paste words',
        hintText: 'Separate words with commas, spaces, or new lines',
        helperText: 'Up to 50 words per paste. Duplicates are skipped.',
        alignLabelWithHint: true,
      ),
    );
  }

  String? _validateWord(String? value) {
    final word = value?.trim() ?? '';

    if (word.isEmpty) {
      return 'Enter a word.';
    }
    if (word.length > 100) {
      return 'Use 100 characters or fewer.';
    }
    return null;
  }

  String? _validateBulk(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Paste at least one word.';
    }
    return null;
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.mode});

  final AddWordMode mode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mode == AddWordMode.single ? 'Add a word' : 'Add several words',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          mode == AddWordMode.single
              ? 'Save a word and let Lexi start building its learning content.'
              : 'Paste a list and Lexi will create every new word at once.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.isBulk,
    required this.onPressed,
  });

  final bool isSubmitting;
  final bool isBulk;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = isSubmitting
        ? 'Adding...'
        : isBulk
        ? 'Add words'
        : 'Add word';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('submitButton'),
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Icon(isBulk ? Icons.library_add_outlined : Icons.add),
        label: Text(label),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  failure.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('retryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleSuccessCard extends StatelessWidget {
  const _SingleSuccessCard({required this.word, required this.onAddAnother});

  final VocabularyWord word;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = colorScheme.onPrimaryContainer;

    return Card(
      color: colorScheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: foreground),
            const SizedBox(height: 20),
            Text(
              'Word added',
              style: textTheme.titleMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 6),
            Text(
              word.word,
              style: textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              word.aiReady
                  ? 'AI content is ready.'
                  : 'AI content is being generated.',
              style: textTheme.bodyLarge?.copyWith(color: foreground),
            ),
            const SizedBox(height: 4),
            Text(
              word.aiReady
                  ? 'The word is saved with its meanings and examples.'
                  : 'The word is saved. Lexi will finish the AI content shortly.',
              style: textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('addAnotherButton'),
              onPressed: onAddAnother,
              icon: const Icon(Icons.add),
              label: const Text('Add another'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkSuccessCard extends StatelessWidget {
  const _BulkSuccessCard({required this.result, required this.onAddAnother});

  final BulkAddResult result;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = colorScheme.onPrimaryContainer;

    return Card(
      color: colorScheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.library_add_check_outlined, size: 40, color: foreground),
            const SizedBox(height: 20),
            Text(
              result.added.isEmpty ? 'No new words added' : 'Words added',
              style: textTheme.titleMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryStat(label: 'Added', value: result.added.length),
                _SummaryStat(
                  label: 'Duplicates',
                  value: result.duplicates.length,
                ),
                _SummaryStat(label: 'Invalid', value: result.invalid.length),
              ],
            ),
            if (result.added.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'AI content is being generated for the new words.',
                style: textTheme.bodyLarge?.copyWith(color: foreground),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final word in result.added)
                    Chip(
                      label: Text(word.word),
                      backgroundColor: colorScheme.surface,
                      labelStyle: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ],
            if (result.duplicates.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Duplicates: ${result.duplicates.join(', ')}',
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ],
            if (result.invalid.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Invalid: ${result.invalid.join(', ')}',
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('addAnotherButton'),
              onPressed: onAddAnother,
              icon: const Icon(Icons.add),
              label: const Text('Add another'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
