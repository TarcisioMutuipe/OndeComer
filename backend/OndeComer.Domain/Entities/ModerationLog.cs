namespace OndeComer.Domain.Entities;

public class ModerationLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string ContentType { get; set; } = string.Empty; // "text", "image"
    public string EntityType { get; set; } = string.Empty; // "comment", "review", "dish_image", "profile_image"
    public Guid? EntityId { get; set; }
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public string Result { get; set; } = string.Empty; // "approved", "flagged", "blocked"
    public double ConfidenceScore { get; set; }
    public string? Categories { get; set; } // JSON: detected categories
    public string? OriginalContent { get; set; } // text excerpt or image URL
    public string? Reason { get; set; }
    public bool ReviewedByHuman { get; set; }
    public Guid? ReviewedByUserId { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
