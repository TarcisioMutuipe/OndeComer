namespace OndeComer.Application.DTOs.Notification;

public record RegisterDeviceRequest(
    string Platform,
    string FcmToken,
    string? ApnsToken
);

public record UpdatePreferencesRequest(
    bool NewComment,
    bool NewReview,
    bool PromotionActive,
    bool NewDish
);

public record NotificationPreferenceDto(
    bool NewComment,
    bool NewReview,
    bool PromotionActive,
    bool NewDish
);

public record PushNotificationDto(
    string Title,
    string Body,
    string? DeepLink,
    Dictionary<string, string>? Data
);
