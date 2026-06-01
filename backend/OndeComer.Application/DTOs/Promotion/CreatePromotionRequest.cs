using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Promotion;

public record CreatePromotionRequest(
    [Required][MaxLength(200)] string Title,
    [MaxLength(1000)] string? Description,
    string? ImageUrl,
    [Range(1, 100)] decimal? DiscountPercent,
    DateTime? ExpiresAt
);
