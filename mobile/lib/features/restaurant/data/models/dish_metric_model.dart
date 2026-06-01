class DishMetric {
  final String dishId;
  final String dishName;
  final double averageRating;
  final int reviewCount;
  final int commentCount;
  final bool isActive;

  DishMetric({
    required this.dishId,
    required this.dishName,
    required this.averageRating,
    required this.reviewCount,
    required this.commentCount,
    required this.isActive,
  });

  factory DishMetric.fromJson(Map<String, dynamic> json) {
    return DishMetric(
      dishId: json['dishId'] as String? ?? '',
      dishName: json['dishName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
