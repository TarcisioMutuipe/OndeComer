using OndeComer.Domain.Enums;

namespace OndeComer.Domain.Entities;

public class Promotion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RestaurantId { get; set; }
    public Restaurant Restaurant { get; set; } = null!;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? DiscountPercent { get; set; }
    public PromotionScope Scope { get; set; } = PromotionScope.AllDishes;
    public string? TargetDishIdsJson { get; set; }
    public int TotalTickets { get; set; } = 10;
    public int RemainingTickets { get; set; } = 10;
    public DateTime ClaimStartsAt { get; set; } = DateTime.UtcNow;
    public DateTime ClaimEndsAt { get; set; } = DateTime.UtcNow.AddDays(2);
    public int TicketValidityDays { get; set; } = 7;
    public string? PixKey { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiresAt { get; set; }

    public ICollection<PromotionTicket> Tickets { get; set; } = new List<PromotionTicket>();
}
