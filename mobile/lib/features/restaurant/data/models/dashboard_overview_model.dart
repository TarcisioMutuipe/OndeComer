class DashboardOverview {
  final int totalDishes;
  final int activeDishes;
  final int totalReviews;
  final int approvedReviews;
  final int pendingReviews;
  final int totalComments;
  final int pendingComments;
  final double averageRating;
  final double approvalRate;

  DashboardOverview({
    required this.totalDishes,
    required this.activeDishes,
    required this.totalReviews,
    required this.approvedReviews,
    required this.pendingReviews,
    required this.totalComments,
    required this.pendingComments,
    required this.averageRating,
    required this.approvalRate,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalDishes: json['totalDishes'] as int? ?? 0,
      activeDishes: json['activeDishes'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      approvedReviews: json['approvedReviews'] as int? ?? 0,
      pendingReviews: json['pendingReviews'] as int? ?? 0,
      totalComments: json['totalComments'] as int? ?? 0,
      pendingComments: json['pendingComments'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      approvalRate: (json['approvalRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
