import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/learning_state.dart';
import '../../domain/entities/vocabulary_query.dart';
import '../../domain/entities/word_summary.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../navigation/app_routes.dart';

enum _LibrarySortOption {
  newest('Newest first'),
  oldest('Oldest first'),
  alphabetical('A–Z'),
  reverseAlphabetical('Z–A');

  const _LibrarySortOption(this.label);

  final String label;
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    FocusScope.of(context).unfocus();
    context.read<LibraryBloc>().add(SearchLibrary(_searchController.text));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<LibraryBloc>().add(const SearchLibrary(''));
    setState(() {});
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<LibraryBloc>().add(const ClearLibraryFilters());
    setState(() {});
  }

  Future<void> _openAddWords() async {
    await Navigator.pushNamed(context, AppRoutes.addWord);
    if (mounted) {
      context.read<LibraryBloc>().add(const LoadLibrary());
    }
  }

  Future<void> _openDetail(String wordId) async {
    final deleted = await Navigator.pushNamed(
      context,
      AppRoutes.wordDetail,
      arguments: wordId,
    );
    if (mounted && deleted == true) {
      context.read<LibraryBloc>().add(const LoadLibrary());
    }
  }

  void _selectSort(_LibrarySortOption option) {
    final bloc = context.read<LibraryBloc>();
    switch (option) {
      case _LibrarySortOption.newest:
        bloc.add(
          const SortLibrary(
            VocabularySort.dateAdded,
            VocabularyOrder.descending,
          ),
        );
        break;
      case _LibrarySortOption.oldest:
        bloc.add(
          const SortLibrary(
            VocabularySort.dateAdded,
            VocabularyOrder.ascending,
          ),
        );
        break;
      case _LibrarySortOption.alphabetical:
        bloc.add(
          const SortLibrary(VocabularySort.word, VocabularyOrder.ascending),
        );
        break;
      case _LibrarySortOption.reverseAlphabetical:
        bloc.add(
          const SortLibrary(VocabularySort.word, VocabularyOrder.descending),
        );
        break;
    }
  }

  _LibrarySortOption _currentSort(VocabularyQuery query) {
    if (query.sort == VocabularySort.word) {
      return query.order == VocabularyOrder.ascending
          ? _LibrarySortOption.alphabetical
          : _LibrarySortOption.reverseAlphabetical;
    }
    return query.order == VocabularyOrder.ascending
        ? _LibrarySortOption.oldest
        : _LibrarySortOption.newest;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryBloc>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary Library')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            _LibraryControls(
              searchController: _searchController,
              state: state,
              onSearchChanged: (_) => setState(() {}),
              onSearchSubmitted: _submitSearch,
              onClearSearch: _clearSearch,
              onStatusSelected: (status) {
                context.read<LibraryBloc>().add(FilterLibraryByStatus(status));
              },
              onClearFilters: _clearFilters,
              currentSort: _currentSort(state.query),
              onSortSelected: _selectSort,
            ),
            const SizedBox(height: 20),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.failure != null)
              _LibraryError(
                failure: state.failure!,
                onRetry: () {
                  context.read<LibraryBloc>().add(const LoadLibrary());
                },
              )
            else if (state.isEmpty)
              state.hasFilters
                  ? _NoMatches(onClearFilters: _clearFilters)
                  : _EmptyLibrary(onAddWords: _openAddWords)
            else ...[
              Text(
                'Showing ${state.items.length} of ${state.total} words',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final word in state.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WordCard(
                    word: word,
                    onTap: () => _openDetail(word.id),
                  ),
                ),
              if (state.loadMoreFailure != null)
                _LoadMoreError(
                  failure: state.loadMoreFailure!,
                  onRetry: () {
                    context.read<LibraryBloc>().add(const LoadMoreLibrary());
                  },
                )
              else if (state.hasMore)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('libraryLoadMoreButton'),
                    onPressed: state.isLoadingMore
                        ? null
                        : () {
                            context.read<LibraryBloc>().add(
                              const LoadMoreLibrary(),
                            );
                          },
                    icon: state.isLoadingMore
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      state.isLoadingMore ? 'Loading...' : 'Load more',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.searchController,
    required this.state,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onStatusSelected,
    required this.onClearFilters,
    required this.currentSort,
    required this.onSortSelected,
  });

  final TextEditingController searchController;
  final LibraryState state;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onClearSearch;
  final ValueChanged<LearningStatus?> onStatusSelected;
  final VoidCallback onClearFilters;
  final _LibrarySortOption currentSort;
  final ValueChanged<_LibrarySortOption> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('librarySearchField'),
          controller: searchController,
          onChanged: onSearchChanged,
          onSubmitted: (_) => onSearchSubmitted(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search your words',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    key: const Key('libraryClearSearchButton'),
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('libraryStatus-all'),
              label: const Text('All'),
              selected: state.query.status == null,
              onSelected: (_) => onStatusSelected(null),
            ),
            for (final status in LearningStatus.values)
              ChoiceChip(
                key: Key('libraryStatus-${status.wireValue}'),
                label: Text(status.label),
                selected: state.query.status == status,
                onSelected: (_) => onStatusSelected(status),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PopupMenuButton<_LibrarySortOption>(
              key: const Key('librarySortButton'),
              tooltip: 'Sort words',
              initialValue: currentSort,
              onSelected: onSortSelected,
              itemBuilder: (context) => [
                for (final option in _LibrarySortOption.values)
                  PopupMenuItem(value: option, child: Text(option.label)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(currentSort.label),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (state.hasFilters)
              TextButton(
                key: const Key('libraryClearFiltersButton'),
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
          ],
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word, required this.onTap});

  final WordSummary word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final metadata = [
      if (word.partOfSpeech != null) word.partOfSpeech!,
      if (word.pronunciation != null) word.pronunciation!,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('libraryWord-${word.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(
                  word.word.isEmpty ? '?' : word.word[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metadata,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusBadge(
                          label: word.learningState?.status.label ?? 'New',
                        ),
                        _StatusBadge(
                          label: word.aiReady ? 'AI ready' : 'AI pending',
                          muted: !word.aiReady,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = muted
        ? colorScheme.surfaceContainerHighest
        : colorScheme.primaryContainer;
    final foreground = muted
        ? colorScheme.onSurfaceVariant
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onAddWords});

  final VoidCallback onAddWords;

  @override
  Widget build(BuildContext context) {
    return _EmptyMessage(
      icon: Icons.library_books_outlined,
      title: 'No words yet',
      message: 'Add your first word and start building your library.',
      action: FilledButton.icon(
        key: const Key('libraryAddWordsButton'),
        onPressed: onAddWords,
        icon: const Icon(Icons.add),
        label: const Text('Add words'),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return _EmptyMessage(
      icon: Icons.search_off,
      title: 'No matching words',
      message: 'Try a different search or clear the current filters.',
      action: OutlinedButton(
        key: const Key('libraryClearEmptyFiltersButton'),
        onPressed: onClearFilters,
        child: const Text('Clear filters'),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            failure.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('libraryRetryButton'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              failure.message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('libraryLoadMoreRetryButton'),
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
      ),
    );
  }
}
