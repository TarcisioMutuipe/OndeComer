using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class RestaurantRepository : IRestaurantRepository
{
    private readonly AppDbContext _context;

    public RestaurantRepository(AppDbContext context) => _context = context;

    public async Task<Restaurant?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Restaurants.Include(r => r.Dishes).FirstOrDefaultAsync(r => r.Id == id, ct);

    public async Task<Restaurant?> GetByOwnerIdAsync(Guid ownerId, CancellationToken ct = default)
        => await _context.Restaurants.Include(r => r.Dishes).FirstOrDefaultAsync(r => r.OwnerUserId == ownerId, ct);

    public async Task<IEnumerable<Restaurant>> GetAllActiveAsync(CancellationToken ct = default)
        => await _context.Restaurants.Where(r => r.IsActive).ToListAsync(ct);

    public async Task<(IEnumerable<Restaurant> Items, int TotalCount)> GetPagedAsync(
        string? search, string? category, string? city,
        int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Restaurants.Where(r => r.IsActive).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(r => r.Name.ToLower().Contains(search.ToLower())
                                  || (r.Description != null && r.Description.ToLower().Contains(search.ToLower()))
                                  || r.Address.ToLower().Contains(search.ToLower()));

        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(r => r.Category.ToLower() == category.ToLower());

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(r => r.City.ToLower() == city.ToLower());

        var total = await query.CountAsync(ct);
        var items = await query
            .OrderBy(r => r.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (items, total);
    }

    public async Task AddAsync(Restaurant restaurant, CancellationToken ct = default)
        => await _context.Restaurants.AddAsync(restaurant, ct);

    public void Update(Restaurant restaurant)
        => _context.Restaurants.Update(restaurant);

    public async Task<bool> ExistsByOwnerIdAsync(Guid ownerId, CancellationToken ct = default)
        => await _context.Restaurants.AnyAsync(r => r.OwnerUserId == ownerId, ct);

    public async Task<bool> ExistsByNameAndAddressAsync(string name, string address, Guid? excludeId = null, CancellationToken ct = default)
    {
        var n = name.Trim().ToLower();
        var a = address.Trim().ToLower();
        var query = _context.Restaurants.AsNoTracking().Where(r => r.Name.ToLower() == n && r.Address.ToLower() == a);
        if (excludeId.HasValue)
            query = query.Where(r => r.Id != excludeId.Value);
        return await query.AnyAsync(ct);
    }

    public async Task<IEnumerable<Restaurant>> SearchAdvancedAsync(
        string? query, string? category,
        decimal? minPrice, decimal? maxPrice, double? minRating,
        double? lat, double? lng, double? radiusKm,
        CancellationToken ct = default)
    {
        var q = _context.Restaurants
            .Where(r => r.IsActive)
            .Include(r => r.Dishes.Where(d => d.IsActive))
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            var lower = query.ToLower();
            q = q.Where(r =>
                r.Name.ToLower().Contains(lower) ||
                (r.Description != null && r.Description.ToLower().Contains(lower)) ||
                r.Address.ToLower().Contains(lower));
        }

        if (!string.IsNullOrWhiteSpace(category))
            q = q.Where(r => r.Category.ToLower() == category.ToLower());

        // Bounding box pre-filter (cheap SQL filter before exact Haversine in memory)
        if (lat.HasValue && lng.HasValue && radiusKm.HasValue)
        {
            var latDelta = radiusKm.Value / 111.0;
            var lngDelta = radiusKm.Value / (111.0 * Math.Cos(lat.Value * Math.PI / 180.0));
            q = q.Where(r =>
                r.Latitude >= lat.Value - latDelta &&
                r.Latitude <= lat.Value + latDelta &&
                r.Longitude >= lng.Value - lngDelta &&
                r.Longitude <= lng.Value + lngDelta);
        }

        // Price filter: restaurant must have at least one active dish in range
        if (minPrice.HasValue)
            q = q.Where(r => r.Dishes.Any(d => d.IsActive && d.Price >= minPrice.Value));
        if (maxPrice.HasValue)
            q = q.Where(r => r.Dishes.Any(d => d.IsActive && d.Price <= maxPrice.Value));

        // Rating filter: restaurant must have at least one dish rated above threshold
        if (minRating.HasValue)
            q = q.Where(r => r.Dishes.Any(d => d.IsActive && d.RatingCount > 0 && d.RatingAverage >= minRating.Value));

        return await q.ToListAsync(ct);
    }
}
