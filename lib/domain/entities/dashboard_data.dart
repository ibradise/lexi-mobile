class DashboardTodayReview {
  const DashboardTodayReview({
    required this.due,
    required this.newWords,
    required this.needAttention,
    required this.becomingStrong,
  });

  final int due;
  final int newWords;
  final int needAttention;
  final int becomingStrong;
}

class WeakestWord {
  const WeakestWord({
    required this.wordId,
    required this.word,
    required this.knowledgeScore,
  });

  final String wordId;
  final String word;
  final double knowledgeScore;
}

class DashboardStats {
  const DashboardStats({
    required this.totalWords,
    required this.newWords,
    required this.learning,
    required this.familiar,
    required this.strong,
    required this.mastered,
    required this.reviewsToday,
    required this.accuracyLast7Days,
    required this.currentStreak,
  });

  final int totalWords;
  final int newWords;
  final int learning;
  final int familiar;
  final int strong;
  final int mastered;
  final int reviewsToday;
  final double accuracyLast7Days;
  final int currentStreak;
}

class DashboardData {
  const DashboardData({
    required this.todayReview,
    required this.weakestWords,
    required this.stats,
  });

  final DashboardTodayReview todayReview;
  final List<WeakestWord> weakestWords;
  final DashboardStats stats;

  bool get isLibraryEmpty => stats.totalWords == 0;
}
