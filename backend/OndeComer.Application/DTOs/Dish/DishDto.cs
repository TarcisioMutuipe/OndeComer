namespace OndeComer.Application.DTOs.Dish;

public record DishDto(
    Guid Id,
    Guid RestaurantId,
    string Name,
    string? Description,
    decimal Price,
    string Category,
    string? ImageUrl,
    DateTime? AvailabilityStart,
    DateTime? AvailabilityEnd,
    bool IsActive,
    double RatingAverage,
    int RatingCount,
    DateTime CreatedAt,
    DateTime UpdatedAt
);
