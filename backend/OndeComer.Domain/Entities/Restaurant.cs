namespace OndeComer.Domain.Entities;

public class Restaurant
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerUserId { get; set; }
    public User Owner { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Address { get; set; } = string.Empty;
    public string City { get; set; } = "Salvador";
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Category { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? CoverUrl { get; set; }
    public string? InstagramUrl { get; set; }
    public string? YouTubeVideoUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public string OpeningHours { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Capacity & Events (Feature 2)
    public int TotalTables { get; set; } = 0;
    public bool HasEventSpace { get; set; } = false;
    public int? EventSpaceCapacity { get; set; }

    // Reservation Management (Feature 3)
    public bool AllowsReservations { get; set; } = false;
    public int TablesAvailableForReservation { get; set; } = 0;

    public ICollection<Dish> Dishes { get; set; } = new List<Dish>();
    public ICollection<RestaurantReservation> Reservations { get; set; } = new List<RestaurantReservation>();
}
