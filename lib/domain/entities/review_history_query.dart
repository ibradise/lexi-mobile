class ReviewHistoryQuery {
  const ReviewHistoryQuery({this.wordId, this.page = 1, this.limit = 20});

  final String? wordId;
  final int page;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is ReviewHistoryQuery &&
        other.wordId == wordId &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(wordId, page, limit);

  ReviewHistoryQuery copyWith({
    String? wordId,
    bool clearWordId = false,
    int? page,
    int? limit,
  }) {
    return ReviewHistoryQuery(
      wordId: clearWordId ? null : wordId ?? this.wordId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}
