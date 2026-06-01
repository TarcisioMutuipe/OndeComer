namespace OndeComer.Domain.Entities;

public class WishlistItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid WishlistId { get; set; }
    public Wishlist Wishlist { get; set; } = null!;

    /// <summary>Se não nulo, item é um restaurante.</summary>
    public Guid? RestaurantId { get; set; }
    public Restaurant? Restaurant { get; set; }

    /// <summary>Se não nulo, item é um prato.</summary>
    public Guid? DishId { get; set; }
    public Dish? Dish { get; set; }

    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
