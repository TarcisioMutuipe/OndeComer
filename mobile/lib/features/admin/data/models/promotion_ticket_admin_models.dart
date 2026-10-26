class PromotionTicketsSummaryModel {
  final int totalTickets;
  final int claimedTickets;
  final int redeemedTickets;
  final int expiredTickets;
  final int activeTickets;
  final int expiringSoonTickets;
  final int usersOnCooldown;

  PromotionTicketsSummaryModel({
    required this.totalTickets,
    required this.claimedTickets,
    required this.redeemedTickets,
    required this.expiredTickets,
    required this.activeTickets,
    required this.expiringSoonTickets,
    required this.usersOnCooldown,
  });

  factory PromotionTicketsSummaryModel.fromJson(Map<String, dynamic> json) {
    return PromotionTicketsSummaryModel(
      totalTickets: json['totalTickets'] as int,
      claimedTickets: json['claimedTickets'] as int,
      redeemedTickets: json['redeemedTickets'] as int,
      expiredTickets: json['expiredTickets'] as int,
      activeTickets: json['activeTickets'] as int,
      expiringSoonTickets: json['expiringSoonTickets'] as int,
      usersOnCooldown: json['usersOnCooldown'] as int,
    );
  }
}

class PromotionTicketAdminModel {
  final String id;
  final String promotionId;
  final String promotionTitle;
  final String restaurantId;
  final String restaurantName;
  final String userId;
  final String userName;
  final String userEmail;
  final String qrCodeToken;
  final String status;
  final DateTime claimedAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final String? expirationReason;
  final int userExpiredTickets;
  final bool userOnCooldown;
  final DateTime? cooldownUntil;
  final double? discountPercent;
  final String scope;

  PromotionTicketAdminModel({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.restaurantId,
    required this.restaurantName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.qrCodeToken,
    required this.status,
    required this.claimedAt,
    required this.expiresAt,
    required this.scope,
    this.redeemedAt,
    this.expirationReason,
    this.userExpiredTickets = 0,
    this.userOnCooldown = false,
    this.cooldownUntil,
    this.discountPercent,
  });

  factory PromotionTicketAdminModel.fromJson(Map<String, dynamic> json) {
    return PromotionTicketAdminModel(
      id: json['id'].toString(),
      promotionId: json['promotionId'].toString(),
      promotionTitle: json['promotionTitle'] as String? ?? '',
      restaurantId: json['restaurantId'].toString(),
      restaurantName: json['restaurantName'] as String? ?? '',
      userId: json['userId'].toString(),
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      qrCodeToken: json['qrCodeToken'] as String? ?? '',
      status: json['status']?.toString() ?? '',
      claimedAt: DateTime.parse(json['claimedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.tryParse(json['redeemedAt'] as String)
          : null,
      expirationReason: json['expirationReason'] as String?,
      userExpiredTickets: (json['userExpiredTickets'] as num?)?.toInt() ?? 0,
      userOnCooldown: json['userOnCooldown'] as bool? ?? false,
      cooldownUntil: json['cooldownUntil'] != null
          ? DateTime.tryParse(json['cooldownUntil'] as String)
          : null,
      discountPercent: json['discountPercent'] == null
          ? null
          : (json['discountPercent'] as num).toDouble(),
      scope: json['scope']?.toString() ?? '',
    );
  }

  bool get isClaimed => status.toLowerCase() == 'claimed';
  bool get isRedeemed => status.toLowerCase() == 'redeemed';
  bool get isExpired => status.toLowerCase() == 'expired';
}

class PromotionTicketAdminPageModel {
  final List<PromotionTicketAdminModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PromotionTicketAdminPageModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PromotionTicketAdminPageModel.fromJson(Map<String, dynamic> json) {
    return PromotionTicketAdminPageModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PromotionTicketAdminModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}
