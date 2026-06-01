namespace OndeComer.Domain.Entities;

public class Wishlist
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsPublic { get; set; } = false;

    /// <summary>Token único para compartilhamento público. Gerado ao tornar a lista pública.</summary>
    public string? ShareToken { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<WishlistItem> Items { get; set; } = new List<WishlistItem>();
}
