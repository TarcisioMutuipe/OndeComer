using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class ReviewRepository : IReviewRepository
{
    private readonly AppDbContext _context;

    public ReviewRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(Review review, CancellationToken ct = default)
        => await _context.Reviews.AddAsync(review, ct);

    public async Task<Review?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Reviews
            .Include(r => r.User)
            .Include(r => r.Dish)
            .FirstOrDefaultAsync(r => r.Id == id, ct);

    public async Task<bool> ExistsAsync(Guid dishId, Guid userId, CancellationToken ct = default)
        => await _context.Reviews.AnyAsync(r => r.DishId == dishId && r.UserId == userId, ct);

    public async Task<IEnumerable<Review>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default)
        => await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.DishId == dishId && r.Status == ReviewStatus.Approved)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

    public async Task<IEnumerable<Review>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default)
        => await _context.Reviews
            .Include(r => r.User)
            .Include(r => r.Dish)
            .Where(r => r.Dish.RestaurantId == restaurantId && r.Status == ReviewStatus.Pending)
            .OrderBy(r => r.CreatedAt)
            .ToListAsync(ct);

    public async Task<(double Average, int Count)> GetRatingStatsAsync(Guid dishId, CancellationToken ct = default)
    {
        var approved = await _context.Reviews
            .Where(r => r.DishId == dishId && r.Status == ReviewStatus.Approved)
            .ToListAsync(ct);

        if (approved.Count == 0) return (0, 0);
        var avg = approved.Average(r => r.Rating);
        return (avg, approved.Count);
    }
}
