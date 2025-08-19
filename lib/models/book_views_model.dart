class BookViews{
  final String bookId;
  int views;
  DateTime lastUpdated;

  BookViews({
    required this.bookId,
    this.views = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() =>{
    'bookId': bookId,
    'views': views,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory BookViews.fromJson(Map<String, dynamic> json) => BookViews(
    bookId: json['bookId'],
    views: json['views'],
    lastUpdated: DateTime.parse(json['lastUpdated'])
  );
}