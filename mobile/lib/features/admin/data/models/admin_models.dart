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
  final List<AdminFollowedRestaurantModel> mostFollowedRestaurants;

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
    required this.mostFollowedRestaurants,
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
      mostFollowedRestaurants: (json['mostFollowedRestaurants'] as List? ?? [])
          .map((item) => AdminFollowedRestaurantModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminFollowedRestaurantModel {
  final String restaurantId;
  final String restaurantName;
  final int favoriteCount;

  const AdminFollowedRestaurantModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.favoriteCount,
  });

  factory AdminFollowedRestaurantModel.fromJson(Map<String, dynamic> json) =>
      AdminFollowedRestaurantModel(
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        favoriteCount: json['favoriteCount'] as int,
      );
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

class PromotionSettingsModel {
  final double batchPrice;
  final int ticketsPerBatch;
  final int ticketValidityDays;
  final int claimWindowDays;
  final String? pixKey;
  final String? receiptPhoneNumber;
  final bool chargeEnabled;
  final DateTime updatedAt;

  PromotionSettingsModel({
    required this.batchPrice,
    required this.ticketsPerBatch,
    required this.ticketValidityDays,
    required this.claimWindowDays,
    required this.updatedAt,
    this.pixKey,
    this.receiptPhoneNumber,
    this.chargeEnabled = false,
  });

  factory PromotionSettingsModel.fromJson(Map<String, dynamic> json) {
    return PromotionSettingsModel(
      batchPrice: (json['batchPrice'] as num).toDouble(),
      ticketsPerBatch: json['ticketsPerBatch'] as int,
      ticketValidityDays: json['ticketValidityDays'] as int,
      claimWindowDays: json['claimWindowDays'] as int,
      pixKey: json['pixKey'] as String?,
      receiptPhoneNumber: json['receiptPhoneNumber'] as String?,
      chargeEnabled: json['chargeEnabled'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'batchPrice': batchPrice,
        'ticketsPerBatch': ticketsPerBatch,
        'ticketValidityDays': ticketValidityDays,
        'claimWindowDays': claimWindowDays,
        'pixKey': pixKey,
        'receiptPhoneNumber': receiptPhoneNumber,
        'chargeEnabled': chargeEnabled,
      };
}

class PendingPromotionPaymentModel {
  final String promotionId;
  final String restaurantId;
  final String restaurantName;
  final String title;
  final int totalTickets;
  final double? paymentAmount;
  final String? pixKey;
  final String? receiptPhoneNumber;
  final DateTime createdAt;
  final DateTime claimStartsAt;

  const PendingPromotionPaymentModel({
    required this.promotionId,
    required this.restaurantId,
    required this.restaurantName,
    required this.title,
    required this.totalTickets,
    required this.paymentAmount,
    required this.pixKey,
    required this.receiptPhoneNumber,
    required this.createdAt,
    required this.claimStartsAt,
  });

  factory PendingPromotionPaymentModel.fromJson(Map<String, dynamic> json) =>
      PendingPromotionPaymentModel(
        promotionId: json['promotionId'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        title: json['title'] as String,
        totalTickets: json['totalTickets'] as int,
        paymentAmount: (json['paymentAmount'] as num?)?.toDouble(),
        pixKey: json['pixKey'] as String?,
        receiptPhoneNumber: json['receiptPhoneNumber'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        claimStartsAt: DateTime.parse(json['claimStartsAt'] as String),
      );
}
