namespace OndeComer.Domain.Entities;

public class PromotionSettings
{
    public int Id { get; set; } = 1;
    public decimal BatchPrice { get; set; } = 50m;
    public int TicketsPerBatch { get; set; } = 10;
    public int TicketValidityDays { get; set; } = 7;
    public int ClaimWindowDays { get; set; } = 2;
    public string? PixKey { get; set; }
    public string? ReceiptPhoneNumber { get; set; }
    public bool ChargeEnabled { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
