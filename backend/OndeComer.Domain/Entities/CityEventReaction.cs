namespace OndeComer.Domain.Entities;

public class CityEventReaction
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CityEventId { get; set; }
    public CityEvent CityEvent { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    /// <summary>
    /// true = Like (curtir), false = Dislike (não curtir)
    /// </summary>
    public bool IsLike { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

