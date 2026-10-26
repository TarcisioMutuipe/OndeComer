using OndeComer.Domain.Enums;

namespace OndeComer.Domain.Entities;

public class PromotionTicket
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PromotionId { get; set; }
    public Promotion Promotion { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string QrCodeToken { get; set; } = Guid.NewGuid().ToString("N");
    public PromotionTicketStatus Status { get; set; } = PromotionTicketStatus.Claimed;
    public DateTime ClaimedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RedeemedAt { get; set; }
    public string? ExpirationReason { get; set; }
    public DateTime? ReminderSentAt { get; set; }
}
