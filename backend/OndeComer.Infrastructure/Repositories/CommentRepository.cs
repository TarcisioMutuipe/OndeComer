using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class CommentRepository : ICommentRepository
{
    private readonly AppDbContext _context;

    public CommentRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(Comment comment, CancellationToken ct = default)
        => await _context.Comments.AddAsync(comment, ct);

    public async Task<Comment?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Comments
            .Include(c => c.User)
            .Include(c => c.Dish)
            .FirstOrDefaultAsync(c => c.Id == id, ct);

    public async Task<IEnumerable<Comment>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default)
        => await _context.Comments
            .Include(c => c.User)
            .Include(c => c.Dish)
            .Where(c => c.DishId == dishId && c.Status == ReviewStatus.Approved)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(ct);

    public async Task<IEnumerable<Comment>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default)
        => await _context.Comments
            .Include(c => c.User)
            .Include(c => c.Dish)
            .Where(c => c.Dish.RestaurantId == restaurantId && c.Status == ReviewStatus.Pending)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync(ct);

    public void Delete(Comment comment)
        => _context.Comments.Remove(comment);
}
