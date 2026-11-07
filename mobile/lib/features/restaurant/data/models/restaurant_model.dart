class RestaurantModel {
  final String id;
  final String ownerUserId;
  final String name;
  final String? description;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String category;
  final String? logoUrl;
  final String? coverUrl;
  final String? instagramUrl;
  final String? youTubeVideoUrl;
  final bool isActive;
  final String openingHours;
  final int dishCount;
  final DateTime createdAt;

  // Capacity & Events (Feature 2)
  final int totalTables;
  final bool hasEventSpace;
  final int? eventSpaceCapacity;

  // Reservations (Feature 3)
  final bool allowsReservations;
  final int tablesAvailableForReservation;

  const RestaurantModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    this.description,
    required this.address,
    this.city = 'Salvador',
    required this.latitude,
    required this.longitude,
    required this.category,
    this.logoUrl,
    this.coverUrl,
    this.instagramUrl,
    this.youTubeVideoUrl,
    required this.isActive,
    required this.openingHours,
    this.dishCount = 0,
    required this.createdAt,
    this.totalTables = 0,
    this.hasEventSpace = false,
    this.eventSpaceCapacity,
    this.allowsReservations = false,
    this.tablesAvailableForReservation = 0,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: (json['id'] ?? '').toString(),
      ownerUserId: (json['ownerUserId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? 'Salvador',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      youTubeVideoUrl: json['youTubeVideoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      openingHours: json['openingHours'] as String? ?? '',
      dishCount: (json['dishCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalTables: (json['totalTables'] as num?)?.toInt() ?? 0,
      hasEventSpace: json['hasEventSpace'] as bool? ?? false,
      eventSpaceCapacity: (json['eventSpaceCapacity'] as num?)?.toInt(),
      allowsReservations: json['allowsReservations'] as bool? ?? false,
      tablesAvailableForReservation:
          (json['tablesAvailableForReservation'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUserId': ownerUserId,
        'name': name,
        'description': description,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'logoUrl': logoUrl,
        'coverUrl': coverUrl,
        'instagramUrl': instagramUrl,
        'youTubeVideoUrl': youTubeVideoUrl,
        'isActive': isActive,
        'openingHours': openingHours,
        'dishCount': dishCount,
        'createdAt': createdAt.toIso8601String(),
        'totalTables': totalTables,
        'hasEventSpace': hasEventSpace,
        'eventSpaceCapacity': eventSpaceCapacity,
        'allowsReservations': allowsReservations,
        'tablesAvailableForReservation': tablesAvailableForReservation,
      };

  RestaurantModel copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    String? description,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? category,
    String? logoUrl,
    String? coverUrl,
    String? instagramUrl,
    String? youTubeVideoUrl,
    bool? isActive,
    String? openingHours,
    int? dishCount,
    DateTime? createdAt,
    int? totalTables,
    bool? hasEventSpace,
    int? eventSpaceCapacity,
    bool? allowsReservations,
    int? tablesAvailableForReservation,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youTubeVideoUrl: youTubeVideoUrl ?? this.youTubeVideoUrl,
      isActive: isActive ?? this.isActive,
      openingHours: openingHours ?? this.openingHours,
      dishCount: dishCount ?? this.dishCount,
      createdAt: createdAt ?? this.createdAt,
      totalTables: totalTables ?? this.totalTables,
      hasEventSpace: hasEventSpace ?? this.hasEventSpace,
      eventSpaceCapacity: eventSpaceCapacity ?? this.eventSpaceCapacity,
      allowsReservations: allowsReservations ?? this.allowsReservations,
      tablesAvailableForReservation:
          tablesAvailableForReservation ?? this.tablesAvailableForReservation,
    );
  }
}
