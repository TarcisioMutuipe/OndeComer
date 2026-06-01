namespace OndeComer.Domain.Entities;

public class LoyaltyPoints
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public int Points { get; set; }
    public string Source { get; set; } = string.Empty; // "checkin", "review", "campaign", "comment"
    public Guid? ReferenceId { get; set; } // CheckIn.Id, Review.Id, etc.
    public Guid? CampaignId { get; set; }
    public LoyaltyCampaign? Campaign { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
}
