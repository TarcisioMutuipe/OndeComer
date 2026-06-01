class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final int requiredPoints;
  final int? requiredCheckIns;
  final int? requiredReviews;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.requiredPoints,
    this.requiredCheckIns,
    this.requiredReviews,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      category: json['category'] as String,
      requiredPoints: json['requiredPoints'] as int,
      requiredCheckIns: json['requiredCheckIns'] as int?,
      requiredReviews: json['requiredReviews'] as int?,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

class PointsHistoryModel {
  final String id;
  final int points;
  final String source;
  final DateTime earnedAt;
  final String? campaignTitle;

  PointsHistoryModel({
    required this.id,
    required this.points,
    required this.source,
    required this.earnedAt,
    this.campaignTitle,
  });

  factory PointsHistoryModel.fromJson(Map<String, dynamic> json) {
    return PointsHistoryModel(
      id: json['id'] as String,
      points: json['points'] as int,
      source: json['source'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      campaignTitle: json['campaignTitle'] as String?,
    );
  }
}

class LoyaltyOverviewModel {
  final int totalPoints;
  final int totalCheckIns;
  final int totalReviews;
  final List<BadgeModel> badges;
  final List<BadgeModel> unlockedBadges;
  final List<PointsHistoryModel> recentPoints;

  LoyaltyOverviewModel({
    required this.totalPoints,
    required this.totalCheckIns,
    required this.totalReviews,
    required this.badges,
    required this.unlockedBadges,
    required this.recentPoints,
  });

  factory LoyaltyOverviewModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyOverviewModel(
      totalPoints: json['totalPoints'] as int,
      totalCheckIns: json['totalCheckIns'] as int,
      totalReviews: json['totalReviews'] as int,
      badges: (json['badges'] as List<dynamic>)
          .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockedBadges: (json['unlockedBadges'] as List<dynamic>)
          .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentPoints: (json['recentPoints'] as List<dynamic>)
          .map((e) => PointsHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CampaignModel {
  final String id;
  final String restaurantId;
  final String title;
  final String? description;
  final double pointsMultiplier;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  CampaignModel({
    required this.id,
    required this.restaurantId,
    required this.title,
    this.description,
    required this.pointsMultiplier,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      pointsMultiplier: (json['pointsMultiplier'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
    );
  }
}
