namespace OndeComer.Domain.Entities;

public class CheckIn
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid RestaurantId { get; set; }
    public Restaurant Restaurant { get; set; } = null!;
    public DateTime CheckInTime { get; set; } = DateTime.UtcNow;
    public int PointsAwarded { get; set; } = 10;
    public double UserLatitude { get; set; }
    public double UserLongitude { get; set; }
    public bool IsValidated { get; set; }
}
