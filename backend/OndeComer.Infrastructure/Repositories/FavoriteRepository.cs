using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class FavoriteRepository : IFavoriteRepository
{
    private readonly AppDbContext _context;
    public FavoriteRepository(AppDbContext context) => _context = context;

    public async Task<Favorite?> GetAsync(Guid userId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default)
        => await _context.Favorites
            .FirstOrDefaultAsync(f =>
                f.UserId == userId &&
                f.RestaurantId == restaurantId &&
                f.DishId == dishId, ct);

    public async Task<IEnumerable<Favorite>> GetByUserAsync(Guid userId, CancellationToken ct = default)
        => await _context.Favorites
            .Where(f => f.UserId == userId)
            .Include(f => f.Restaurant)
            .Include(f => f.Dish)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync(ct);

    public async Task<bool> ExistsAsync(Guid userId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default)
        => await _context.Favorites.AnyAsync(f =>
            f.UserId == userId &&
            f.RestaurantId == restaurantId &&
            f.DishId == dishId, ct);

    public async Task AddAsync(Favorite favorite, CancellationToken ct = default)
        => await _context.Favorites.AddAsync(favorite, ct);

    public void Delete(Favorite favorite)
        => _context.Favorites.Remove(favorite);
}
