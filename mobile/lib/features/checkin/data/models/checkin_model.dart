class CheckInModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final DateTime checkInTime;
  final int pointsAwarded;
  final bool isValidated;

  CheckInModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.checkInTime,
    required this.pointsAwarded,
    required this.isValidated,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      pointsAwarded: json['pointsAwarded'] as int,
      isValidated: json['isValidated'] as bool,
    );
  }
}

class CheckInHistoryModel {
  final List<CheckInModel> checkIns;
  final int totalPoints;
  final int page;
  final int pageSize;

  CheckInHistoryModel({
    required this.checkIns,
    required this.totalPoints,
    required this.page,
    required this.pageSize,
  });

  factory CheckInHistoryModel.fromJson(Map<String, dynamic> json) {
    return CheckInHistoryModel(
      checkIns: (json['checkIns'] as List<dynamic>)
          .map((e) => CheckInModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPoints: json['totalPoints'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}

class QrCodeModel {
  final String restaurantId;
  final String restaurantName;
  final String qrContent;
  final String deepLink;

  QrCodeModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.qrContent,
    required this.deepLink,
  });

  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      qrContent: json['qrContent'] as String,
      deepLink: json['deepLink'] as String,
    );
  }
}
