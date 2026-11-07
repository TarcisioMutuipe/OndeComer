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
  final int totalConsumers;
  final int totalRestaurantOwners;
  final int totalAdmins;
  final int activeUsers;
  final int inactiveUsers;
  final int activeRestaurants;
  final int inactiveRestaurants;
  final int totalDishesInFeed;
  final int totalPromotions;
  final int activePromotions;
  final int ticketsClaimed;
  final int ticketsRedeemed;
  final int ticketsExpired;
  final List<AdminTopDishModel> topRatedDishes;
  final int totalReservations;
  final int pendingReservations;
  final int confirmedReservations;
  final int totalEvents;

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
    this.totalConsumers = 0,
    this.totalRestaurantOwners = 0,
    this.totalAdmins = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
    this.activeRestaurants = 0,
    this.inactiveRestaurants = 0,
    this.totalDishesInFeed = 0,
    this.totalPromotions = 0,
    this.activePromotions = 0,
    this.ticketsClaimed = 0,
    this.ticketsRedeemed = 0,
    this.ticketsExpired = 0,
    this.topRatedDishes = const [],
    this.totalReservations = 0,
    this.pendingReservations = 0,
    this.confirmedReservations = 0,
    this.totalEvents = 0,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalRestaurants: (json['totalRestaurants'] as num?)?.toInt() ?? 0,
      totalDishes: (json['totalDishes'] as num?)?.toInt() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      totalCheckIns: (json['totalCheckIns'] as num?)?.toInt() ?? 0,
      pendingModerations: (json['pendingModerations'] as num?)?.toInt() ?? 0,
      flaggedModerations: (json['flaggedModerations'] as num?)?.toInt() ?? 0,
      activeCampaigns: (json['activeCampaigns'] as num?)?.toInt() ?? 0,
      usersToday: (json['usersToday'] as num?)?.toInt() ?? 0,
      usersThisWeek: (json['usersThisWeek'] as num?)?.toInt() ?? 0,
      mostFollowedRestaurants: (json['mostFollowedRestaurants'] as List? ?? [])
          .map((item) => AdminFollowedRestaurantModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      totalConsumers: (json['totalConsumers'] as num?)?.toInt() ?? 0,
      totalRestaurantOwners: (json['totalRestaurantOwners'] as num?)?.toInt() ?? 0,
      totalAdmins: (json['totalAdmins'] as num?)?.toInt() ?? 0,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      inactiveUsers: (json['inactiveUsers'] as num?)?.toInt() ?? 0,
      activeRestaurants: (json['activeRestaurants'] as num?)?.toInt() ?? 0,
      inactiveRestaurants: (json['inactiveRestaurants'] as num?)?.toInt() ?? 0,
      totalDishesInFeed: (json['totalDishesInFeed'] as num?)?.toInt() ?? 0,
      totalPromotions: (json['totalPromotions'] as num?)?.toInt() ?? 0,
      activePromotions: (json['activePromotions'] as num?)?.toInt() ?? 0,
      ticketsClaimed: (json['ticketsClaimed'] as num?)?.toInt() ?? 0,
      ticketsRedeemed: (json['ticketsRedeemed'] as num?)?.toInt() ?? 0,
      ticketsExpired: (json['ticketsExpired'] as num?)?.toInt() ?? 0,
      topRatedDishes: (json['topRatedDishes'] as List? ?? [])
          .map((item) => AdminTopDishModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      totalReservations: (json['totalReservations'] as num?)?.toInt() ?? 0,
      pendingReservations: (json['pendingReservations'] as num?)?.toInt() ?? 0,
      confirmedReservations: (json['confirmedReservations'] as num?)?.toInt() ?? 0,
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminTopDishModel {
  final String dishId;
  final String dishName;
  final String restaurantName;
  final double ratingAverage;
  final int ratingCount;
  final double price;

  const AdminTopDishModel({
    required this.dishId,
    required this.dishName,
    required this.restaurantName,
    required this.ratingAverage,
    required this.ratingCount,
    required this.price,
  });

  factory AdminTopDishModel.fromJson(Map<String, dynamic> json) {
    return AdminTopDishModel(
      dishId: json['dishId']?.toString() ?? '',
      dishName: json['dishName']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? '',
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
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
