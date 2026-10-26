using System.ComponentModel.DataAnnotations;
using OndeComer.Domain.Enums;

namespace OndeComer.Application.DTOs.Promotion;

public record CreatePromotionRequest(
    [Required][MaxLength(200)] string Title,
    [MaxLength(1000)] string? Description,
    string? ImageUrl,
    [Range(1, 100)] decimal? DiscountPercent,
    PromotionScope Scope = PromotionScope.AllDishes,
    IReadOnlyCollection<Guid>? TargetDishIds = null,
    [Range(1, 1000)] int? TicketCount = null,
    DateTime? ClaimStartsAt = null,
    DateTime? ClaimEndsAt = null,
    string? PixKey = null
);
