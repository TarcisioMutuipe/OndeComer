using OndeComer.Domain.Enums;

namespace OndeComer.Domain.Entities;

/// <summary>Text comment on a dish by a consumer.
/// Requires restaurant moderation before public display.</summary>
public class Comment
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid DishId { get; set; }
    public Dish Dish { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string Text { get; set; } = string.Empty;

    public ReviewStatus Status { get; set; } = ReviewStatus.Pending;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ModeratedAt { get; set; }
    public Guid? ModeratedByUserId { get; set; }
}
