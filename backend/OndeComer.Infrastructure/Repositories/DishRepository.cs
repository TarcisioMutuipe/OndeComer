using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class DishRepository : IDishRepository
{
    private readonly AppDbContext _context;

    public DishRepository(AppDbContext context) => _context = context;

    public async Task<Dish?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Dishes.FirstOrDefaultAsync(d => d.Id == id, ct);

    public async Task<IEnumerable<Dish>> GetByRestaurantIdAsync(Guid restaurantId, bool onlyAvailable = false, CancellationToken ct = default)
    {
        var query = _context.Dishes.Where(d => d.RestaurantId == restaurantId);

        if (onlyAvailable)
        {
            var now = DateTime.UtcNow;
            query = query.Where(d =>
                d.IsActive &&
                (d.AvailabilityStart == null || d.AvailabilityStart <= now) &&
                (d.AvailabilityEnd == null || d.AvailabilityEnd >= now));
        }

        return await query.OrderBy(d => d.Category).ThenBy(d => d.Name).ToListAsync(ct);
    }

    public async Task AddAsync(Dish dish, CancellationToken ct = default)
        => await _context.Dishes.AddAsync(dish, ct);

    public async Task<bool> ExistsByNameAsync(Guid restaurantId, string name, Guid? excludeId, CancellationToken ct = default)
        => await _context.Dishes.AnyAsync(
            d => d.RestaurantId == restaurantId &&
                 d.Name.ToLower() == name.ToLower() &&
                 (excludeId == null || d.Id != excludeId), ct);

    public void Update(Dish dish)
        => _context.Dishes.Update(dish);

    public void Delete(Dish dish)
        => _context.Dishes.Remove(dish);
}
