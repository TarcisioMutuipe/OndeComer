using OndeComer.Domain.Enums;

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
    PromotionScope Scope,
    IReadOnlyCollection<Guid> TargetDishIds,
    IReadOnlyCollection<string> TargetDishNames,
    int TotalTickets,
    int RemainingTickets,
    DateTime? ExpiresAt,
    DateTime ClaimStartsAt,
    DateTime ClaimEndsAt,
    int TicketValidityDays,
    string? PixKey,
    bool CanClaim,
    DateTime CreatedAt,
    bool RequiresPayment,
    DateTime? PaymentApprovedAt,
    decimal? PaymentAmount,
    string? PaymentReceiptPhoneNumber
);
