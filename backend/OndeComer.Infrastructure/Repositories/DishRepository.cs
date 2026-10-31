using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
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

    public async Task<IEnumerable<Dish>> GetFeedAsync(int page, int pageSize, DateTime now, CancellationToken ct = default)
        => await _context.Dishes
            .AsNoTracking()
            .Include(d => d.Restaurant)
            .Where(d => d.IsActive && d.ShowInFeed && d.Restaurant.IsActive &&
                !d.Category.ToLower().Contains("bebid") &&
                !d.Category.ToLower().Contains("vinho") &&
                !d.Category.ToLower().Contains("drink") &&
                (d.AvailabilityStart == null || d.AvailabilityStart <= now) &&
                (d.AvailabilityEnd == null || d.AvailabilityEnd >= now))
            .OrderByDescending(d => d.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

    public async Task<IEnumerable<Dish>> GetInactiveBeforeAsync(DateTime inactiveBefore, CancellationToken ct = default)
        => await _context.Dishes
            .Where(d => !d.IsActive && d.DeactivatedAt != null && d.DeactivatedAt <= inactiveBefore)
            .ToListAsync(ct);

    public async Task RemoveDishReferencesFromPromotionsAsync(IReadOnlyCollection<Guid> dishIds, CancellationToken ct = default)
    {
        if (dishIds.Count == 0) return;

        var promotions = await _context.Promotions
            .Where(p => p.Scope == PromotionScope.SpecificDishes && p.TargetDishIdsJson != null)
            .ToListAsync(ct);

        foreach (var promotion in promotions)
        {
            List<Guid> targets;
            try
            {
                targets = JsonSerializer.Deserialize<List<Guid>>(promotion.TargetDishIdsJson!) ?? [];
            }
            catch (JsonException)
            {
                continue;
            }

            if (targets.RemoveAll(dishIds.Contains) == 0) continue;
            promotion.TargetDishIdsJson = JsonSerializer.Serialize(targets);
            if (targets.Count == 0) promotion.IsActive = false;
        }
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
