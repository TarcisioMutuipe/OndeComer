using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Dish;

public record UpdateDishRequest(
    [MaxLength(200)] string? Name,
    [MaxLength(1000)] string? Description,
    [Range(0.01, 99999.99)] decimal? Price,
    [MaxLength(100)] string? Category,
    [MaxLength(500)] string? ImageUrl,
    DateTime? AvailabilityStart,
    DateTime? AvailabilityEnd,
    bool? IsActive,
    string? Subcategory,
    bool? ShowInFeed
);
