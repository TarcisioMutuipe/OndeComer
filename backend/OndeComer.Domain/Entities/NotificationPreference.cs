namespace OndeComer.Domain.Entities;

public class NotificationPreference
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public bool NewComment { get; set; } = true;
    public bool NewReview { get; set; } = true;
    public bool PromotionActive { get; set; } = true;
    public bool NewDish { get; set; } = true;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
