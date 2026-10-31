namespace OndeComer.Domain.Entities;

public class Dish
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RestaurantId { get; set; }
    public Restaurant Restaurant { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string? Subcategory { get; set; }
    public string? ImageUrl { get; set; }
    public bool ShowInFeed { get; set; } = true;
    public DateTime? AvailabilityStart { get; set; }
    public DateTime? AvailabilityEnd { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? DeactivatedAt { get; set; }
    public double RatingAverage { get; set; }
    public int RatingCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
