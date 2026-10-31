namespace OndeComer.Application.DTOs.Dish;

public record DishFeedDto(
    Guid Id,
    Guid RestaurantId,
    string Name,
    string? Description,
    decimal Price,
    string Category,
    string? Subcategory,
    string? ImageUrl,
    DateTime CreatedAt,
    string RestaurantName,
    string? RestaurantLogoUrl
);
