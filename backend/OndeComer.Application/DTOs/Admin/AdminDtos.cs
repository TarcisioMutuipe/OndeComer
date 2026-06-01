namespace OndeComer.Application.DTOs.Admin;

public record AdminDashboardDto(
    int TotalUsers,
    int TotalRestaurants,
    int TotalDishes,
    int TotalReviews,
    int TotalComments,
    int TotalCheckIns,
    int PendingModerations,
    int FlaggedModerations,
    int ActiveCampaigns,
    int UsersToday,
    int UsersThisWeek
);

public record AdminUserDto(
    Guid Id,
    string Name,
    string Email,
    string Username,
    string ProfileType,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? LastLogin
);

public record AdminUpdateUserRequest(
    string? Name,
    string? Email,
    string? ProfileType,
    bool? IsActive
);

public record AdminRestaurantDto(
    Guid Id,
    string Name,
    string OwnerName,
    string Category,
    string City,
    bool IsActive,
    int DishCount,
    DateTime CreatedAt
);

public record AdminUpdateRestaurantRequest(
    string? Name,
    string? Description,
    string? Address,
    string? City,
    double? Latitude,
    double? Longitude,
    string? Category,
    string? LogoUrl,
    string? CoverUrl,
    string? InstagramUrl,
    string? YouTubeVideoUrl,
    string? OpeningHours,
    bool? IsActive
);

public record ExportRequest(
    string Format // "csv" or "json"
);
