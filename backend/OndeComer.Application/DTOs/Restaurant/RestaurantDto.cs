namespace OndeComer.Application.DTOs.Restaurant;

public record RestaurantDto(
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
    DateTime CreatedAt
);
