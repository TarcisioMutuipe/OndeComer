namespace OndeComer.Application.DTOs.Loyalty;

public record LoyaltyOverviewResponse(
    int TotalPoints,
    int TotalCheckIns,
    int TotalReviews,
    IEnumerable<BadgeDto> Badges,
    IEnumerable<BadgeDto> UnlockedBadges,
    IEnumerable<PointsHistoryDto> RecentPoints
);

public record BadgeDto(
    Guid Id,
    string Name,
    string Description,
    string IconUrl,
    string Category,
    int RequiredPoints,
    int? RequiredCheckIns,
    int? RequiredReviews,
    bool IsUnlocked,
    DateTime? UnlockedAt
);

public record PointsHistoryDto(
    Guid Id,
    int Points,
    string Source,
    DateTime EarnedAt,
    string? CampaignTitle
);

public record CreateCampaignRequest(
    Guid RestaurantId,
    string Title,
    string? Description,
    double PointsMultiplier,
    DateTime StartDate,
    DateTime EndDate
);

public record UpdateCampaignRequest(
    string? Title,
    string? Description,
    double? PointsMultiplier,
    DateTime? StartDate,
    DateTime? EndDate,
    bool? IsActive
);

public record CampaignDto(
    Guid Id,
    Guid RestaurantId,
    string Title,
    string? Description,
    double PointsMultiplier,
    DateTime StartDate,
    DateTime EndDate,
    bool IsActive,
    DateTime CreatedAt
);
