using OndeComer.Domain.Enums;

namespace OndeComer.Domain.Entities;

/// <summary>Star rating (1-5) submitted by a consumer for a dish.
/// Goes through restaurant moderation before affecting RatingAverage.</summary>
public class Review
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid DishId { get; set; }
    public Dish Dish { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>1-5 stars.</summary>
    public int Rating { get; set; }

    public ReviewStatus Status { get; set; } = ReviewStatus.Pending;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ModeratedAt { get; set; }
    public Guid? ModeratedByUserId { get; set; }
}
