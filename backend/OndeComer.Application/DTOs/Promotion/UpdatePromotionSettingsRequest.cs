using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Promotion;

public record UpdatePromotionSettingsRequest(
    [Range(1, 100000)] decimal BatchPrice,
    [Range(1, 1000)] int TicketsPerBatch,
    [Range(1, 365)] int TicketValidityDays,
    [Range(1, 30)] int ClaimWindowDays,
    [MaxLength(200)] string? PixKey,
    [MaxLength(30)] string? ReceiptPhoneNumber
);
