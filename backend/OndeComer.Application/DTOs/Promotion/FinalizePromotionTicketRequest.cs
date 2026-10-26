using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Promotion;

public record FinalizePromotionTicketRequest(
    [Required][MaxLength(200)] string QrCodeToken
);
