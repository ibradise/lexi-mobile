import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_data.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/review_history_bloc.dart';
import '../bloc/review_history_event.dart';
import '../bloc/review_queue_bloc.dart';
import '../bloc/review_queue_event.dart';
import '../navigation/app_routes.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'review_history_page.dart';
import 'review_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _selectedIndex;
  bool _dashboardRequested = false;
  bool _reviewHistoryRequested = false;
  bool _reviewQueueRequested = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3);
    if (_selectedIndex == 0 || _selectedIndex == 2 || _selectedIndex == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        switch (_selectedIndex) {
          case 0:
            _loadDashboard();
          case 2:
            _loadReviewQueue();
          case 3:
            _loadReviewHistory();
        }
      });
    }
  }

  void _loadDashboard() {
    if (_dashboardRequested) {
      return;
    }
    _refreshDashboard();
  }

  void _refreshDashboard() {
    _dashboardRequested = true;
    context.read<DashboardBloc>().add(const LoadDashboard());
  }

  void _loadReviewQueue() {
    if (_reviewQueueRequested) {
      return;
    }
    _reviewQueueRequested = true;
    context.read<ReviewQueueBloc>().add(const LoadReviewQueue());
  }

  void _refreshReviewQueue() {
    if (_reviewQueueRequested) {
      context.read<ReviewQueueBloc>().add(const LoadReviewQueue());
    }
  }

  void _loadReviewHistory() {
    if (_reviewHistoryRequested) {
      return;
    }
    _refreshReviewHistory();
  }

  void _refreshReviewHistory() {
    _reviewHistoryRequested = true;
    context.read<ReviewHistoryBloc>().add(const LoadReviewHistory());
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        _loadDashboard();
      case 2:
        _loadReviewQueue();
      case 3:
        _loadReviewHistory();
    }
  }

  Future<void> _openAddWord() async {
    await Navigator.pushNamed(context, AppRoutes.addWord);
    if (!mounted) {
      return;
    }
    _refreshDashboard();
    context.read<LibraryBloc>().add(const LoadLibrary());
    _refreshReviewQueue();
    _refreshReviewHistory();
  }

  Future<void> _startReview() async {
    await Navigator.pushNamed(context, AppRoutes.reviewSession);
    if (!mounted) {
      return;
    }
    _refreshDashboard();
    _refreshReviewQueue();
    _refreshReviewHistory();
  }

  Future<void> _openWeakestWord(WeakestWord word) async {
    final deleted = await Navigator.pushNamed(
      context,
      AppRoutes.wordDetail,
      arguments: word.wordId,
    );
    if (!mounted) {
      return;
    }
    _refreshDashboard();
    if (deleted == true) {
      context.read<LibraryBloc>().add(const LoadLibrary());
      _refreshReviewHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(
              onAddWords: _openAddWord,
              onStartReview: _startReview,
              onOpenWord: _openWeakestWord,
            ),
            const LibraryPage(),
            const ReviewPage(),
            const ReviewHistoryPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              key: Key('mainDashboardTab'),
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              key: Key('mainLibraryTab'),
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'Library',
            ),
            NavigationDestination(
              key: Key('mainReviewTab'),
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz),
              label: 'Review',
            ),
            NavigationDestination(
              key: Key('mainHistoryTab'),
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('mainAddWordButton'),
          onPressed: _openAddWord,
          icon: const Icon(Icons.add),
          label: const Text('Add word'),
        ),
      ),
    );
  }
}
