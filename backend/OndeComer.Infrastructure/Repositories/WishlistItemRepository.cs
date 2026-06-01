using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class WishlistItemRepository : IWishlistItemRepository
{
    private readonly AppDbContext _context;
    public WishlistItemRepository(AppDbContext context) => _context = context;

    public async Task<WishlistItem?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.WishlistItems.FirstOrDefaultAsync(i => i.Id == id, ct);

    public async Task<bool> ExistsAsync(Guid wishlistId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default)
        => await _context.WishlistItems.AnyAsync(i =>
            i.WishlistId == wishlistId &&
            i.RestaurantId == restaurantId &&
            i.DishId == dishId, ct);

    public async Task AddAsync(WishlistItem item, CancellationToken ct = default)
        => await _context.WishlistItems.AddAsync(item, ct);

    public void Delete(WishlistItem item)
        => _context.WishlistItems.Remove(item);
}
