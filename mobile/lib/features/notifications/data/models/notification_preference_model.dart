class NotificationPreference {
  final bool newComment;
  final bool newReview;
  final bool promotionActive;
  final bool newDish;

  NotificationPreference({
    required this.newComment,
    required this.newReview,
    required this.promotionActive,
    required this.newDish,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      newComment: json['newComment'] as bool? ?? true,
      newReview: json['newReview'] as bool? ?? true,
      promotionActive: json['promotionActive'] as bool? ?? true,
      newDish: json['newDish'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'newComment': newComment,
        'newReview': newReview,
        'promotionActive': promotionActive,
        'newDish': newDish,
      };

  NotificationPreference copyWith({
    bool? newComment,
    bool? newReview,
    bool? promotionActive,
    bool? newDish,
  }) {
    return NotificationPreference(
      newComment: newComment ?? this.newComment,
      newReview: newReview ?? this.newReview,
      promotionActive: promotionActive ?? this.promotionActive,
      newDish: newDish ?? this.newDish,
    );
  }
}
