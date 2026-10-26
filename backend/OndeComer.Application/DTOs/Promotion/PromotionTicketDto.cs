using OndeComer.Domain.Enums;

namespace OndeComer.Application.DTOs.Promotion;

public record PromotionTicketDto(
    Guid Id,
    Guid PromotionId,
    string PromotionTitle,
    string RestaurantName,
    Guid UserId,
    string UserName,
    string QrCodeToken,
    PromotionTicketStatus Status,
    DateTime ClaimedAt,
    DateTime ExpiresAt,
    DateTime? RedeemedAt,
    decimal? DiscountPercent,
    PromotionScope Scope,
    IReadOnlyCollection<Guid> TargetDishIds
);
