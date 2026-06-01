class CommentMetric {
  final int totalComments;
  final int approvedComments;
  final int rejectedComments;
  final int pendingComments;
  final double approvalRate;
  final List<RecentComment> recentComments;

  CommentMetric({
    required this.totalComments,
    required this.approvedComments,
    required this.rejectedComments,
    required this.pendingComments,
    required this.approvalRate,
    required this.recentComments,
  });

  factory CommentMetric.fromJson(Map<String, dynamic> json) {
    return CommentMetric(
      totalComments: json['totalComments'] as int? ?? 0,
      approvedComments: json['approvedComments'] as int? ?? 0,
      rejectedComments: json['rejectedComments'] as int? ?? 0,
      pendingComments: json['pendingComments'] as int? ?? 0,
      approvalRate: (json['approvalRate'] as num?)?.toDouble() ?? 0.0,
      recentComments: (json['recentComments'] as List<dynamic>?)
              ?.map((e) => RecentComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RecentComment {
  final String id;
  final String dishName;
  final String userName;
  final String text;
  final String status;
  final DateTime createdAt;

  RecentComment({
    required this.id,
    required this.dishName,
    required this.userName,
    required this.text,
    required this.status,
    required this.createdAt,
  });

  factory RecentComment.fromJson(Map<String, dynamic> json) {
    return RecentComment(
      id: json['id'] as String? ?? '',
      dishName: json['dishName'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
