using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Promotion;

public record UpdatePromotionRequest(
    [MaxLength(200)] string? Title = null,
    [MaxLength(1000)] string? Description = null,
    string? ImageUrl = null,
    [Range(1, 100)] decimal? DiscountPercent = null,
    DateTime? ExpiresAt = null,
    bool? IsActive = null
);
