namespace OndeComer.Application.DTOs.Promotion;

public record ClaimPromotionTicketResponse(
    Guid TicketId,
    Guid PromotionId,
    string PromotionTitle,
    string RestaurantName,
    string QrCodeToken,
    DateTime ClaimedAt,
    DateTime ExpiresAt,
    string Message
);
