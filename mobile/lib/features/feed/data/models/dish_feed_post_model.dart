class DishFeedPostModel {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? subcategory;
  final String? imageUrl;
  final DateTime createdAt;
  final String restaurantName;
  final String? restaurantLogoUrl;

  const DishFeedPostModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.subcategory,
    required this.imageUrl,
    required this.createdAt,
    required this.restaurantName,
    required this.restaurantLogoUrl,
  });

  factory DishFeedPostModel.fromJson(Map<String, dynamic> json) =>
      DishFeedPostModel(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        category: json['category'] as String,
        subcategory: json['subcategory'] as String?,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        restaurantName: json['restaurantName'] as String,
        restaurantLogoUrl: json['restaurantLogoUrl'] as String?,
      );
}
