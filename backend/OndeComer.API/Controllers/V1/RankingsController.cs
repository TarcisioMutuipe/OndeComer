using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OndeComer.Infrastructure.Data;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/rankings")]
public class RankingsController : ControllerBase
{
    private readonly AppDbContext _context;

    public RankingsController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Top restaurantes por período (baseado em média de avaliações dos pratos).
    /// GET /api/v1/rankings/restaurants?period=week&limit=10
    /// </summary>
    [HttpGet("restaurants")]
    public async Task<IActionResult> GetTopRestaurants(
        [FromQuery] string period = "week", [FromQuery] int limit = 10, CancellationToken ct = default)
    {
        limit = Math.Clamp(limit, 1, 50);
        var since = GetPeriodStart(period);

        var topRestaurants = await _context.Restaurants
            .Where(r => r.IsActive)
            .Select(r => new
            {
                r.Id,
                r.Name,
                r.Category,
                r.LogoUrl,
                r.City,
                DishCount = r.Dishes.Count(d => d.IsActive),
                AvgRating = r.Dishes
                    .Where(d => d.IsActive && d.RatingCount > 0)
                    .Average(d => (double?)d.RatingAverage) ?? 0,
                TotalReviews = r.Dishes.Sum(d => d.RatingCount),
                RecentReviews = _context.Reviews
                    .Count(rev => rev.Dish.RestaurantId == r.Id && rev.CreatedAt >= since && rev.Status == Domain.Enums.ReviewStatus.Approved)
            })
            .Where(x => x.TotalReviews > 0)
            .OrderByDescending(x => x.AvgRating)
            .ThenByDescending(x => x.RecentReviews)
            .Take(limit)
            .ToListAsync(ct);

        return Ok(new { period, items = topRestaurants });
    }

    /// <summary>
    /// Top pratos por período (melhores avaliados).
    /// GET /api/v1/rankings/dishes?period=week&limit=10
    /// </summary>
    [HttpGet("dishes")]
    public async Task<IActionResult> GetTopDishes(
        [FromQuery] string period = "week", [FromQuery] int limit = 10, CancellationToken ct = default)
    {
        limit = Math.Clamp(limit, 1, 50);
        var since = GetPeriodStart(period);

        var topDishes = await _context.Dishes
            .Where(d => d.IsActive && d.ShowInFeed && d.RatingCount > 0 &&
                !d.Category.ToLower().Contains("bebid") &&
                !d.Category.ToLower().Contains("vinho") &&
                !d.Category.ToLower().Contains("drink"))
            .Select(d => new
            {
                d.Id,
                d.Name,
                d.Price,
                d.ImageUrl,
                d.Category,
                d.RatingAverage,
                d.RatingCount,
                RestaurantName = d.Restaurant.Name,
                RestaurantId = d.RestaurantId,
                RecentReviews = _context.Reviews
                    .Count(rev => rev.DishId == d.Id && rev.CreatedAt >= since && rev.Status == Domain.Enums.ReviewStatus.Approved)
            })
            .OrderByDescending(x => x.RatingAverage)
            .ThenByDescending(x => x.RecentReviews)
            .Take(limit)
            .ToListAsync(ct);

        return Ok(new { period, items = topDishes });
    }

    /// <summary>
    /// Pratos em alta (trending): maior volume de avaliações recentes.
    /// GET /api/v1/dishes/trending?limit=10
    /// </summary>
    [HttpGet("/api/v1/dishes/trending")]
    public async Task<IActionResult> GetTrendingDishes(
        [FromQuery] int limit = 10, CancellationToken ct = default)
    {
        limit = Math.Clamp(limit, 1, 50);
        var since = DateTime.UtcNow.AddDays(-7);

        var trending = await _context.Dishes
            .Where(d => d.IsActive && d.ShowInFeed && d.RatingCount > 0 &&
                !d.Category.ToLower().Contains("bebid") &&
                !d.Category.ToLower().Contains("vinho") &&
                !d.Category.ToLower().Contains("drink"))
            .Select(d => new
            {
                d.Id,
                d.Name,
                d.Price,
                d.ImageUrl,
                d.Category,
                d.RatingAverage,
                d.RatingCount,
                RestaurantName = d.Restaurant.Name,
                RestaurantId = d.RestaurantId,
                RecentActivity = _context.Reviews
                    .Count(rev => rev.DishId == d.Id && rev.CreatedAt >= since) +
                    _context.Comments.Count(c => c.DishId == d.Id && c.CreatedAt >= since)
            })
            .Where(x => x.RecentActivity > 0)
            .OrderByDescending(x => x.RecentActivity)
            .ThenByDescending(x => x.RatingAverage)
            .Take(limit)
            .ToListAsync(ct);

        return Ok(new { items = trending });
    }

    /// <summary>
    /// Promoções em destaque algorítmico (mais recentes + desconto).
    /// GET /api/v1/promotions/featured?limit=5
    /// </summary>
    [HttpGet("/api/v1/promotions/featured")]
    public async Task<IActionResult> GetFeaturedPromotions(
        [FromQuery] int limit = 5, CancellationToken ct = default)
    {
        limit = Math.Clamp(limit, 1, 20);

        var featured = await _context.Promotions
            .Where(p => p.IsActive && (p.ExpiresAt == null || p.ExpiresAt > DateTime.UtcNow))
            .OrderByDescending(p => p.DiscountPercent ?? 0)
            .ThenByDescending(p => p.CreatedAt)
            .Take(limit)
            .Select(p => new
            {
                p.Id,
                p.Title,
                p.Description,
                p.ImageUrl,
                p.DiscountPercent,
                p.ExpiresAt,
                p.CreatedAt,
                RestaurantId = p.RestaurantId,
                RestaurantName = p.Restaurant.Name,
                RestaurantLogoUrl = p.Restaurant.LogoUrl
            })
            .ToListAsync(ct);

        return Ok(new { items = featured });
    }

    private static DateTime GetPeriodStart(string period) => period.ToLower() switch
    {
        "day" => DateTime.UtcNow.AddDays(-1),
        "week" => DateTime.UtcNow.AddDays(-7),
        "month" => DateTime.UtcNow.AddDays(-30),
        "year" => DateTime.UtcNow.AddDays(-365),
        _ => DateTime.UtcNow.AddDays(-7)
    };
}
