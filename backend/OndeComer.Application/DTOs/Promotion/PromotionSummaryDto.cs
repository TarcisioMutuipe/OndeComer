namespace OndeComer.Application.DTOs.Promotion;

public record PromotionSummaryDto(
    int TotalPromotions,
    int ActivePromotions,
    int UpcomingPromotions,
    int TotalTickets,
    int ClaimedTickets,
    int RedeemedTickets,
    int ExpiredTickets,
    int UsersOnCooldown
);
