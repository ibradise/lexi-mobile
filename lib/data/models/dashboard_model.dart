import '../../domain/entities/dashboard_data.dart';
import 'model_utils.dart';

class DashboardTodayReviewModel {
  const DashboardTodayReviewModel({
    required this.due,
    required this.newWords,
    required this.needAttention,
    required this.becomingStrong,
  });

  factory DashboardTodayReviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardTodayReviewModel(
      due: optionalInt(json['due']),
      newWords: optionalInt(json['newWords']),
      needAttention: optionalInt(json['needAttention']),
      becomingStrong: optionalInt(json['becomingStrong']),
    );
  }

  final int due;
  final int newWords;
  final int needAttention;
  final int becomingStrong;

  DashboardTodayReview toEntity() {
    return DashboardTodayReview(
      due: due,
      newWords: newWords,
      needAttention: needAttention,
      becomingStrong: becomingStrong,
    );
  }
}

class WeakestWordModel {
  const WeakestWordModel({
    required this.wordId,
    required this.word,
    required this.knowledgeScore,
  });

  factory WeakestWordModel.fromJson(Map<String, dynamic> json) {
    return WeakestWordModel(
      wordId: requireString(json, 'wordId'),
      word: requireString(json, 'word'),
      knowledgeScore: optionalDouble(json['knowledgeScore']),
    );
  }

  final String wordId;
  final String word;
  final double knowledgeScore;

  WeakestWord toEntity() {
    return WeakestWord(
      wordId: wordId,
      word: word,
      knowledgeScore: knowledgeScore,
    );
  }
}

class DashboardStatsModel {
  const DashboardStatsModel({
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

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalWords: optionalInt(json['totalWords']),
      newWords: optionalInt(json['new']),
      learning: optionalInt(json['learning']),
      familiar: optionalInt(json['familiar']),
      strong: optionalInt(json['strong']),
      mastered: optionalInt(json['mastered']),
      reviewsToday: optionalInt(json['reviewsToday']),
      accuracyLast7Days: optionalDouble(json['accuracyLast7Days']),
      currentStreak: optionalInt(json['currentStreak']),
    );
  }

  final int totalWords;
  final int newWords;
  final int learning;
  final int familiar;
  final int strong;
  final int mastered;
  final int reviewsToday;
  final double accuracyLast7Days;
  final int currentStreak;

  DashboardStats toEntity() {
    return DashboardStats(
      totalWords: totalWords,
      newWords: newWords,
      learning: learning,
      familiar: familiar,
      strong: strong,
      mastered: mastered,
      reviewsToday: reviewsToday,
      accuracyLast7Days: accuracyLast7Days,
      currentStreak: currentStreak,
    );
  }
}

class DashboardModel {
  const DashboardModel({
    required this.todayReview,
    required this.weakestWords,
    required this.stats,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final todayReviewValue = json['todayReview'];
    final weakestWordsValue = json['weakestWords'];
    final statsValue = json['stats'];

    if (todayReviewValue is! Map<String, dynamic> ||
        weakestWordsValue is! List ||
        statsValue is! Map<String, dynamic>) {
      throw const FormatException('Incomplete dashboard response.');
    }

    return DashboardModel(
      todayReview: DashboardTodayReviewModel.fromJson(todayReviewValue),
      weakestWords: [
        for (final item in weakestWordsValue)
          if (item is Map<String, dynamic>) WeakestWordModel.fromJson(item),
      ],
      stats: DashboardStatsModel.fromJson(statsValue),
    );
  }

  final DashboardTodayReviewModel todayReview;
  final List<WeakestWordModel> weakestWords;
  final DashboardStatsModel stats;

  DashboardData toEntity() {
    return DashboardData(
      todayReview: todayReview.toEntity(),
      weakestWords: [for (final word in weakestWords) word.toEntity()],
      stats: stats.toEntity(),
    );
  }
}
