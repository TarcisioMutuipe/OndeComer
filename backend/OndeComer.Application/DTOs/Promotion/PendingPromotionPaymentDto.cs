namespace OndeComer.Application.DTOs.Promotion;

public record PendingPromotionPaymentDto(
    Guid PromotionId,
    Guid RestaurantId,
    string RestaurantName,
    string Title,
    int TotalTickets,
    decimal? PaymentAmount,
    string? PixKey,
    string? ReceiptPhoneNumber,
    DateTime CreatedAt,
    DateTime ClaimStartsAt
);
