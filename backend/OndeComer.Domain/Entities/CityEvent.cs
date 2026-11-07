namespace OndeComer.Domain.Entities;

public class CityEvent
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string? YouTubeVideoUrl { get; set; }
    public string? LocationOrAddress { get; set; }
    public DateTime? EventDate { get; set; }
    public Guid? RestaurantId { get; set; }
    public Restaurant? Restaurant { get; set; }
    public Guid CreatedByUserId { get; set; }
    public User? CreatedByUser { get; set; }
    public bool IsActive { get; set; } = true;
    public int LikesCount { get; set; } = 0;
    public int DislikesCount { get; set; } = 0;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<CityEventReaction> Reactions { get; set; } = new List<CityEventReaction>();
}

