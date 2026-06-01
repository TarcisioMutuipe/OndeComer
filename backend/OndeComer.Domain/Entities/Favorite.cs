namespace OndeComer.Domain.Entities;

public class Favorite
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>Se não nulo, é um favorito de restaurante.</summary>
    public Guid? RestaurantId { get; set; }
    public Restaurant? Restaurant { get; set; }

    /// <summary>Se não nulo, é um favorito de prato.</summary>
    public Guid? DishId { get; set; }
    public Dish? Dish { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
