namespace OndeComer.Application.DTOs.Favorites;

public record FavoriteDto(
    Guid Id,
    Guid UserId,
    Guid? RestaurantId,
    string? RestaurantName,
    string? RestaurantLogoUrl,
    Guid? DishId,
    string? DishName,
    string? DishImageUrl,
    DateTime CreatedAt
);

public record ToggleFavoriteRequest(
    Guid? RestaurantId,
    Guid? DishId
);
