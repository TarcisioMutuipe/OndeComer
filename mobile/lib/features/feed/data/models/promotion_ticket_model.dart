class PromotionTicketModel {
  final String id;
  final String promotionId;
  final String promotionTitle;
  final String restaurantName;
  final String userId;
  final String userName;
  final String qrCodeToken;
  final String status;
  final DateTime claimedAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final double? discountPercent;
  final String scope;
  final List<String> targetDishIds;

  PromotionTicketModel({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.restaurantName,
    required this.userId,
    required this.userName,
    required this.qrCodeToken,
    required this.status,
    required this.claimedAt,
    required this.expiresAt,
    required this.scope,
    this.redeemedAt,
    this.discountPercent,
    this.targetDishIds = const [],
  });

  factory PromotionTicketModel.fromJson(Map<String, dynamic> json) {
    return PromotionTicketModel(
      id: json['id'].toString(),
      promotionId: json['promotionId'].toString(),
      promotionTitle: json['promotionTitle'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? '',
      userId: json['userId'].toString(),
      userName: json['userName'] as String? ?? '',
      qrCodeToken: json['qrCodeToken'] as String? ?? '',
      status: json['status']?.toString() ?? '',
      claimedAt: DateTime.parse(json['claimedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.tryParse(json['redeemedAt'] as String)
          : null,
      discountPercent: json['discountPercent'] == null
          ? null
          : (json['discountPercent'] as num).toDouble(),
      scope: json['scope']?.toString() ?? '',
      targetDishIds: (json['targetDishIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  bool get isRedeemed => status.toLowerCase() == 'redeemed';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isClaimed => status.toLowerCase() == 'claimed';
}
