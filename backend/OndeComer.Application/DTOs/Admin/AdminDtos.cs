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
    int UsersThisWeek,
    IReadOnlyList<AdminMostFollowedRestaurantDto> MostFollowedRestaurants
);

public record AdminMostFollowedRestaurantDto(
    Guid RestaurantId,
    string RestaurantName,
    int FavoriteCount
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
    DateTime CreatedAt,
    string? Description = null,
    string? Address = null,
    double? Latitude = null,
    double? Longitude = null,
    string? LogoUrl = null,
    string? CoverUrl = null,
    string? InstagramUrl = null,
    string? YouTubeVideoUrl = null,
    string? OpeningHours = null,
    Guid? OwnerUserId = null,
    bool HasDuplicateName = false,
    bool HasAdminAndUserDuplicate = false
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
