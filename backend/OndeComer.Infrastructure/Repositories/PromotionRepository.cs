using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class PromotionRepository : IPromotionRepository
{
    private readonly AppDbContext _context;

    public PromotionRepository(AppDbContext context) => _context = context;

    public async Task<IEnumerable<Promotion>> GetActiveAsync(int page, int pageSize, CancellationToken ct = default)
        => await _context.Promotions
            .Include(p => p.Restaurant)
            .Where(p => p.IsActive && (p.ExpiresAt == null || p.ExpiresAt > DateTime.UtcNow))
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

    public async Task<IEnumerable<Promotion>> GetByRestaurantAsync(Guid restaurantId, CancellationToken ct = default)
        => await _context.Promotions
            .Where(p => p.RestaurantId == restaurantId && p.IsActive
                        && (p.ExpiresAt == null || p.ExpiresAt > DateTime.UtcNow))
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

    public async Task AddAsync(Promotion promotion, CancellationToken ct = default)
        => await _context.Promotions.AddAsync(promotion, ct);

    public async Task<Promotion?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Promotions.FindAsync(new object[] { id }, ct);

    public async Task<bool> BelongsToRestaurantAsync(Guid promotionId, Guid restaurantId, CancellationToken ct = default)
        => await _context.Promotions
            .AnyAsync(p => p.Id == promotionId && p.RestaurantId == restaurantId, ct);
}
