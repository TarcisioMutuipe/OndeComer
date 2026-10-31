namespace OndeComer.Application.DTOs.Promotion;

public record PromotionSettingsDto(
    decimal BatchPrice,
    int TicketsPerBatch,
    int TicketValidityDays,
    int ClaimWindowDays,
    string? PixKey,
    string? ReceiptPhoneNumber,
    DateTime UpdatedAt,
    bool ChargeEnabled
);
