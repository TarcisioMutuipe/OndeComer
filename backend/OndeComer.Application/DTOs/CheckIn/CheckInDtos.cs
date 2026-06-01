namespace OndeComer.Application.DTOs.CheckIn;

public record CheckInRequest(
    Guid RestaurantId,
    double Latitude,
    double Longitude
);

public record CheckInResponse(
    Guid Id,
    Guid RestaurantId,
    string RestaurantName,
    DateTime CheckInTime,
    int PointsAwarded,
    bool IsValidated
);

public record CheckInHistoryResponse(
    IEnumerable<CheckInResponse> CheckIns,
    int TotalPoints,
    int Page,
    int PageSize
);

public record QrCodeResponse(
    Guid RestaurantId,
    string RestaurantName,
    string QrContent,
    string DeepLink
);
