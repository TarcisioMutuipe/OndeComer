using OndeComer.Domain.Enums;

namespace OndeComer.Application.DTOs.Promotion;

public record PromotionTicketsAdminSummaryDto(
    int TotalTickets,
    int ClaimedTickets,
    int RedeemedTickets,
    int ExpiredTickets,
    int ActiveTickets,
    int ExpiringSoonTickets,
    int UsersOnCooldown
);

public record PromotionTicketAdminDto(
    Guid Id,
    Guid PromotionId,
    string PromotionTitle,
    Guid RestaurantId,
    string RestaurantName,
    Guid UserId,
    string UserName,
    string UserEmail,
    string QrCodeToken,
    PromotionTicketStatus Status,
    DateTime ClaimedAt,
    DateTime ExpiresAt,
    DateTime? RedeemedAt,
    string? ExpirationReason,
    int UserExpiredTickets,
    bool UserOnCooldown,
    DateTime? CooldownUntil,
    decimal? DiscountPercent,
    PromotionScope Scope
);
