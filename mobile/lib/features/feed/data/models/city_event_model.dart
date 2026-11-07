class CityEventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? youTubeVideoUrl;
  final String? locationOrAddress;
  final DateTime? eventDate;
  final String? restaurantId;
  final String? restaurantName;
  final bool isActive;
  final int likesCount;
  final int dislikesCount;
  final bool? userReaction; // true = like, false = dislike, null = none
  final DateTime createdAt;

  const CityEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.youTubeVideoUrl,
    this.locationOrAddress,
    this.eventDate,
    this.restaurantId,
    this.restaurantName,
    this.isActive = true,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userReaction,
    required this.createdAt,
  });

  factory CityEventModel.fromJson(Map<String, dynamic> json) {
    return CityEventModel(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      youTubeVideoUrl: json['youTubeVideoUrl'] as String?,
      locationOrAddress: json['locationOrAddress'] as String?,
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString())
          : null,
      restaurantId: json['restaurantId'] as String?,
      restaurantName: json['restaurantName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikesCount'] as num?)?.toInt() ?? 0,
      userReaction: json['userReaction'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CityEventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? youTubeVideoUrl,
    String? locationOrAddress,
    DateTime? eventDate,
    String? restaurantId,
    String? restaurantName,
    bool? isActive,
    int? likesCount,
    int? dislikesCount,
    bool? userReaction,
    bool clearReaction = false,
    DateTime? createdAt,
  }) {
    return CityEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      youTubeVideoUrl: youTubeVideoUrl ?? this.youTubeVideoUrl,
      locationOrAddress: locationOrAddress ?? this.locationOrAddress,
      eventDate: eventDate ?? this.eventDate,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      isActive: isActive ?? this.isActive,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      userReaction: clearReaction ? null : (userReaction ?? this.userReaction),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

