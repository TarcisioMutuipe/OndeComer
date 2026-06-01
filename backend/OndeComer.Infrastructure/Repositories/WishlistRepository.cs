using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class WishlistRepository : IWishlistRepository
{
    private readonly AppDbContext _context;
    public WishlistRepository(AppDbContext context) => _context = context;

    public async Task<Wishlist?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Wishlists
            .Include(w => w.Items)
                .ThenInclude(i => i.Restaurant)
            .Include(w => w.Items)
                .ThenInclude(i => i.Dish)
            .FirstOrDefaultAsync(w => w.Id == id, ct);

    public async Task<Wishlist?> GetByShareTokenAsync(string shareToken, CancellationToken ct = default)
        => await _context.Wishlists
            .Include(w => w.Items)
                .ThenInclude(i => i.Restaurant)
            .Include(w => w.Items)
                .ThenInclude(i => i.Dish)
            .FirstOrDefaultAsync(w => w.ShareToken == shareToken && w.IsPublic, ct);

    public async Task<IEnumerable<Wishlist>> GetByUserAsync(Guid userId, CancellationToken ct = default)
        => await _context.Wishlists
            .Where(w => w.UserId == userId)
            .Include(w => w.Items)
            .OrderByDescending(w => w.UpdatedAt)
            .ToListAsync(ct);

    public async Task<bool> ShareTokenExistsAsync(string token, CancellationToken ct = default)
        => await _context.Wishlists.AnyAsync(w => w.ShareToken == token, ct);

    public async Task AddAsync(Wishlist wishlist, CancellationToken ct = default)
        => await _context.Wishlists.AddAsync(wishlist, ct);

    public void Update(Wishlist wishlist)
        => _context.Wishlists.Update(wishlist);

    public void Delete(Wishlist wishlist)
        => _context.Wishlists.Remove(wishlist);
}
