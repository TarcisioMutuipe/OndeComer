using Microsoft.EntityFrameworkCore;
using OndeComer.Application.DTOs.Dashboard;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Enums;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class DashboardRepository : IDashboardRepository
{
    private readonly AppDbContext _db;

    public DashboardRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<DashboardOverviewDto> GetOverviewAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var dishes = await _db.Dishes
            .Where(d => d.RestaurantId == restaurantId)
            .ToListAsync(ct);

        var dishIds = dishes.Select(d => d.Id).ToList();

        var totalReviews = await _db.Reviews.CountAsync(r => dishIds.Contains(r.DishId), ct);
        var approvedReviews = await _db.Reviews.CountAsync(r => dishIds.Contains(r.DishId) && r.Status == ReviewStatus.Approved, ct);
        var pendingReviews = await _db.Reviews.CountAsync(r => dishIds.Contains(r.DishId) && r.Status == ReviewStatus.Pending, ct);

        var totalComments = await _db.Comments.CountAsync(c => dishIds.Contains(c.DishId), ct);
        var pendingComments = await _db.Comments.CountAsync(c => dishIds.Contains(c.DishId) && c.Status == ReviewStatus.Pending, ct);

        var avgRating = approvedReviews > 0
            ? await _db.Reviews
                .Where(r => dishIds.Contains(r.DishId) && r.Status == ReviewStatus.Approved)
                .AverageAsync(r => r.Rating, ct)
            : 0;

        var approvalRate = totalReviews > 0
            ? (double)approvedReviews / totalReviews * 100
            : 0;

        return new DashboardOverviewDto(
            TotalDishes: dishes.Count,
            ActiveDishes: dishes.Count(d => d.IsActive),
            TotalReviews: totalReviews,
            ApprovedReviews: approvedReviews,
            PendingReviews: pendingReviews,
            TotalComments: totalComments,
            PendingComments: pendingComments,
            AverageRating: Math.Round(avgRating, 2),
            ApprovalRate: Math.Round(approvalRate, 1)
        );
    }

    public async Task<List<DishMetricDto>> GetDishMetricsAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var dishes = await _db.Dishes
            .Where(d => d.RestaurantId == restaurantId)
            .ToListAsync(ct);

        var dishIds = dishes.Select(d => d.Id).ToList();

        var reviewCounts = await _db.Reviews
            .Where(r => dishIds.Contains(r.DishId) && r.Status == ReviewStatus.Approved)
            .GroupBy(r => r.DishId)
            .Select(g => new { DishId = g.Key, Count = g.Count(), Avg = g.Average(r => r.Rating) })
            .ToListAsync(ct);

        var commentCounts = await _db.Comments
            .Where(c => dishIds.Contains(c.DishId))
            .GroupBy(c => c.DishId)
            .Select(g => new { DishId = g.Key, Count = g.Count() })
            .ToListAsync(ct);

        return dishes.Select(d =>
        {
            var rc = reviewCounts.FirstOrDefault(r => r.DishId == d.Id);
            var cc = commentCounts.FirstOrDefault(c => c.DishId == d.Id);
            return new DishMetricDto(
                DishId: d.Id,
                DishName: d.Name,
                AverageRating: Math.Round(rc?.Avg ?? 0, 2),
                ReviewCount: rc?.Count ?? 0,
                CommentCount: cc?.Count ?? 0,
                IsActive: d.IsActive
            );
        })
        .OrderByDescending(d => d.ReviewCount)
        .ToList();
    }

    public async Task<List<HourMetricDto>> GetHourMetricsAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var dishIds = await _db.Dishes
            .Where(d => d.RestaurantId == restaurantId)
            .Select(d => d.Id)
            .ToListAsync(ct);

        var reviewsByHour = await _db.Reviews
            .Where(r => dishIds.Contains(r.DishId))
            .GroupBy(r => r.CreatedAt.Hour)
            .Select(g => new { Hour = g.Key, Count = g.Count() })
            .ToListAsync(ct);

        var commentsByHour = await _db.Comments
            .Where(c => dishIds.Contains(c.DishId))
            .GroupBy(c => c.CreatedAt.Hour)
            .Select(g => new { Hour = g.Key, Count = g.Count() })
            .ToListAsync(ct);

        return Enumerable.Range(0, 24).Select(h =>
        {
            var rc = reviewsByHour.FirstOrDefault(r => r.Hour == h)?.Count ?? 0;
            var cc = commentsByHour.FirstOrDefault(c => c.Hour == h)?.Count ?? 0;
            return new HourMetricDto(Hour: h, ReviewCount: rc, CommentCount: cc, TotalInteractions: rc + cc);
        }).ToList();
    }

    public async Task<CommentMetricDto> GetCommentMetricsAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var dishIds = await _db.Dishes
            .Where(d => d.RestaurantId == restaurantId)
            .Select(d => d.Id)
            .ToListAsync(ct);

        var total = await _db.Comments.CountAsync(c => dishIds.Contains(c.DishId), ct);
        var approved = await _db.Comments.CountAsync(c => dishIds.Contains(c.DishId) && c.Status == ReviewStatus.Approved, ct);
        var rejected = await _db.Comments.CountAsync(c => dishIds.Contains(c.DishId) && c.Status == ReviewStatus.Rejected, ct);
        var pending = await _db.Comments.CountAsync(c => dishIds.Contains(c.DishId) && c.Status == ReviewStatus.Pending, ct);

        var approvalRate = total > 0 ? (double)approved / total * 100 : 0;

        var recentComments = await _db.Comments
            .Where(c => dishIds.Contains(c.DishId))
            .OrderByDescending(c => c.CreatedAt)
            .Take(10)
            .Include(c => c.Dish)
            .Include(c => c.User)
            .Select(c => new RecentCommentDto(
                c.Id,
                c.Dish.Name,
                c.User.Name,
                c.Text,
                c.Status.ToString(),
                c.CreatedAt
            ))
            .ToListAsync(ct);

        return new CommentMetricDto(
            TotalComments: total,
            ApprovedComments: approved,
            RejectedComments: rejected,
            PendingComments: pending,
            ApprovalRate: Math.Round(approvalRate, 1),
            RecentComments: recentComments
        );
    }
}
