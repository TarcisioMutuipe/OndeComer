namespace OndeComer.Application.DTOs.Promotion;

public record PromotionDto(
    Guid Id,
    Guid RestaurantId,
    string RestaurantName,
    string? RestaurantLogoUrl,
    string Title,
    string? Description,
    string? ImageUrl,
    decimal? DiscountPercent,
    DateTime? ExpiresAt,
    DateTime CreatedAt
);
