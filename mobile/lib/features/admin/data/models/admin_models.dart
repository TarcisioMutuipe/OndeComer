class AdminDashboardModel {
  final int totalUsers;
  final int totalRestaurants;
  final int totalDishes;
  final int totalReviews;
  final int totalComments;
  final int totalCheckIns;
  final int pendingModerations;
  final int flaggedModerations;
  final int activeCampaigns;
  final int usersToday;
  final int usersThisWeek;

  AdminDashboardModel({
    required this.totalUsers,
    required this.totalRestaurants,
    required this.totalDishes,
    required this.totalReviews,
    required this.totalComments,
    required this.totalCheckIns,
    required this.pendingModerations,
    required this.flaggedModerations,
    required this.activeCampaigns,
    required this.usersToday,
    required this.usersThisWeek,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: json['totalUsers'] as int,
      totalRestaurants: json['totalRestaurants'] as int,
      totalDishes: json['totalDishes'] as int,
      totalReviews: json['totalReviews'] as int,
      totalComments: json['totalComments'] as int,
      totalCheckIns: json['totalCheckIns'] as int,
      pendingModerations: json['pendingModerations'] as int,
      flaggedModerations: json['flaggedModerations'] as int,
      activeCampaigns: json['activeCampaigns'] as int,
      usersToday: json['usersToday'] as int,
      usersThisWeek: json['usersThisWeek'] as int,
    );
  }
}

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String profileType;
  final bool isActive;
  final DateTime createdAt;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.profileType,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profileType: json['profileType'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ModerationLogModel {
  final String id;
  final String contentType;
  final String entityType;
  final String result;
  final double confidenceScore;
  final String? reason;
  final bool reviewedByHuman;
  final DateTime createdAt;

  ModerationLogModel({
    required this.id,
    required this.contentType,
    required this.entityType,
    required this.result,
    required this.confidenceScore,
    this.reason,
    required this.reviewedByHuman,
    required this.createdAt,
  });

  factory ModerationLogModel.fromJson(Map<String, dynamic> json) {
    return ModerationLogModel(
      id: json['id'] as String,
      contentType: json['contentType'] as String,
      entityType: json['entityType'] as String,
      result: json['result'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      reason: json['reason'] as String?,
      reviewedByHuman: json['reviewedByHuman'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
