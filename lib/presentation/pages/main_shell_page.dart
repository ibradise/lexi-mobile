import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/review_queue_bloc.dart';
import '../bloc/review_queue_event.dart';
import '../navigation/app_routes.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'review_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _selectedIndex;
  bool _reviewQueueRequested = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2);
    if (_selectedIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _loadReviewQueue();
      });
    }
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

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
    if (index == 2) {
      _loadReviewQueue();
    }
  }

  Future<void> _openAddWord() async {
    await Navigator.pushNamed(context, AppRoutes.addWord);
    if (!mounted) {
      return;
    }
    context.read<LibraryBloc>().add(const LoadLibrary());
    _refreshReviewQueue();
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
          children: const [HomePage(), LibraryPage(), ReviewPage()],
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
