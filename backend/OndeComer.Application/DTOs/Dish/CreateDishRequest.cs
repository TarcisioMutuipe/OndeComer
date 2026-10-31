using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Dish;

public record CreateDishRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(1000)] string? Description,
    [Range(0.01, 99999.99)] decimal Price,
    [Required, MaxLength(100)] string Category,
    [MaxLength(100)] string? Subcategory,
    [MaxLength(500)] string? ImageUrl,
    DateTime? AvailabilityStart,
    DateTime? AvailabilityEnd,
    bool ShowInFeed = true
);
