namespace OndeComer.Domain.Entities;

public class NotificationDevice
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string Platform { get; set; } = string.Empty; // "android", "ios", "web"
    public string FcmToken { get; set; } = string.Empty;
    public string? ApnsToken { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
