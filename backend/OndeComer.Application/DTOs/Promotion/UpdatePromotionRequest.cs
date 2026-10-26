using System.ComponentModel.DataAnnotations;
using OndeComer.Domain.Enums;

namespace OndeComer.Application.DTOs.Promotion;

public record UpdatePromotionRequest(
    [MaxLength(200)] string? Title = null,
    [MaxLength(1000)] string? Description = null,
    string? ImageUrl = null,
    [Range(1, 100)] decimal? DiscountPercent = null,
    PromotionScope? Scope = null,
    IReadOnlyCollection<Guid>? TargetDishIds = null,
    [Range(1, 1000)] int? TicketCount = null,
    DateTime? ClaimStartsAt = null,
    DateTime? ClaimEndsAt = null,
    string? PixKey = null,
    bool? IsActive = null
);
