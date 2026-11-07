namespace OndeComer.Application.DTOs.Restaurant;

/// <summary>
/// Extended restaurant result with computed fields for advanced search.
/// </summary>
public record RestaurantSearchResultDto(
    Guid Id,
    Guid OwnerUserId,
    string Name,
    string? Description,
    string Address,
    string City,
    double Latitude,
    double Longitude,
    string Category,
    string? LogoUrl,
    string? CoverUrl,
    string? InstagramUrl,
    string? YouTubeVideoUrl,
    bool IsActive,
    string OpeningHours,
    int DishCount,
    DateTime CreatedAt,
    double? DistanceKm,
    double AverageRating,
    bool IsCurrentlyOpen,
    decimal? MinDishPrice,
    int TotalTables = 0,
    bool HasEventSpace = false,
    int? EventSpaceCapacity = null,
    bool AllowsReservations = false,
    int TablesAvailableForReservation = 0
);
