class HourMetric {
  final int hour;
  final int reviewCount;
  final int commentCount;
  final int totalInteractions;

  HourMetric({
    required this.hour,
    required this.reviewCount,
    required this.commentCount,
    required this.totalInteractions,
  });

  factory HourMetric.fromJson(Map<String, dynamic> json) {
    return HourMetric(
      hour: json['hour'] as int? ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
    );
  }
}
