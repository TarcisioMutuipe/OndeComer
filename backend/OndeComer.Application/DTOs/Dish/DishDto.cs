namespace OndeComer.Application.DTOs.Dish;

public record DishDto(
    Guid Id,
    Guid RestaurantId,
    string Name,
    string? Description,
    decimal Price,
    string Category,
    string? Subcategory,
    string? ImageUrl,
    bool ShowInFeed,
    DateTime? AvailabilityStart,
    DateTime? AvailabilityEnd,
    bool IsActive,
    DateTime? DeactivatedAt,
    double RatingAverage,
    int RatingCount,
    DateTime CreatedAt,
    DateTime UpdatedAt
);
