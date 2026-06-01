namespace OndeComer.Domain.Entities;

public class Badge
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string IconUrl { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty; // "checkin", "review", "social"
    public int RequiredPoints { get; set; }
    public int? RequiredCheckIns { get; set; }
    public int? RequiredReviews { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
