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
    IReadOnlyList<AdminMostFollowedRestaurantDto> MostFollowedRestaurants,
    int TotalConsumers = 0,
    int TotalRestaurantOwners = 0,
    int TotalAdmins = 0,
    int ActiveUsers = 0,
    int InactiveUsers = 0,
    int ActiveRestaurants = 0,
    int InactiveRestaurants = 0,
    int TotalDishesInFeed = 0,
    int TotalPromotions = 0,
    int ActivePromotions = 0,
    int TicketsClaimed = 0,
    int TicketsRedeemed = 0,
    int TicketsExpired = 0,
    IReadOnlyList<AdminTopDishDto>? TopRatedDishes = null,
    int TotalReservations = 0,
    int PendingReservations = 0,
    int ConfirmedReservations = 0,
    int TotalEvents = 0
);

public record AdminMostFollowedRestaurantDto(
    Guid RestaurantId,
    string RestaurantName,
    int FavoriteCount
);

public record AdminTopDishDto(
    Guid DishId,
    string DishName,
    string RestaurantName,
    double RatingAverage,
    int RatingCount,
    decimal Price
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
    bool HasAdminAndUserDuplicate = false,
    int TotalTables = 0,
    bool HasEventSpace = false,
    int? EventSpaceCapacity = null,
    bool AllowsReservations = false,
    int TablesAvailableForReservation = 0
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
    bool? IsActive,
    int? TotalTables = null,
    bool? HasEventSpace = null,
    int? EventSpaceCapacity = null,
    bool? AllowsReservations = null,
    int? TablesAvailableForReservation = null
);

public record ExportRequest(
    string Format // "csv" or "json"
);
