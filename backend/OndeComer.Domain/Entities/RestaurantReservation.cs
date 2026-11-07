using OndeComer.Domain.Enums;

namespace OndeComer.Domain.Entities;

public class RestaurantReservation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RestaurantId { get; set; }
    public Restaurant Restaurant { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public DateTime ReservationDate { get; set; } // Stored in UTC (date component)
    public string TimeSlot { get; set; } = string.Empty; // e.g. "19:00", "19:30"
    public int PartySize { get; set; } = 1;
    public int ToleranceMinutes { get; set; } = 15; // 15 minutes tolerance window
    public string? Notes { get; set; }
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public string? CancellationReason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? StatusUpdatedAt { get; set; }
}

