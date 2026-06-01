using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class LoyaltyRepository : ILoyaltyRepository
{
    private readonly AppDbContext _context;

    public LoyaltyRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<LoyaltyPoints> AddPointsAsync(LoyaltyPoints points)
    {
        _context.LoyaltyPoints.Add(points);
        await _context.SaveChangesAsync();
        return points;
    }

    public async Task<int> GetTotalPointsAsync(Guid userId)
    {
        return await _context.LoyaltyPoints
            .Where(p => p.UserId == userId)
            .SumAsync(p => p.Points);
    }

    public async Task<IEnumerable<LoyaltyPoints>> GetPointsHistoryAsync(Guid userId, int page, int pageSize)
    {
        return await _context.LoyaltyPoints
            .Include(p => p.Campaign)
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.EarnedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<IEnumerable<Badge>> GetAllBadgesAsync()
    {
        return await _context.Badges
            .Where(b => b.IsActive)
            .OrderBy(b => b.RequiredPoints)
            .ToListAsync();
    }

    public async Task<IEnumerable<UserBadge>> GetUserBadgesAsync(Guid userId)
    {
        return await _context.UserBadges
            .Include(ub => ub.Badge)
            .Where(ub => ub.UserId == userId)
            .OrderByDescending(ub => ub.UnlockedAt)
            .ToListAsync();
    }

    public async Task<UserBadge?> GetUserBadgeAsync(Guid userId, Guid badgeId)
    {
        return await _context.UserBadges
            .FirstOrDefaultAsync(ub => ub.UserId == userId && ub.BadgeId == badgeId);
    }

    public async Task<UserBadge> AddUserBadgeAsync(UserBadge userBadge)
    {
        _context.UserBadges.Add(userBadge);
        await _context.SaveChangesAsync();
        return userBadge;
    }

    public async Task<LoyaltyCampaign> AddCampaignAsync(LoyaltyCampaign campaign)
    {
        _context.LoyaltyCampaigns.Add(campaign);
        await _context.SaveChangesAsync();
        return campaign;
    }

    public async Task<LoyaltyCampaign?> GetCampaignByIdAsync(Guid id)
    {
        return await _context.LoyaltyCampaigns.FindAsync(id);
    }

    public async Task<LoyaltyCampaign> UpdateCampaignAsync(LoyaltyCampaign campaign)
    {
        _context.LoyaltyCampaigns.Update(campaign);
        await _context.SaveChangesAsync();
        return campaign;
    }

    public async Task<IEnumerable<LoyaltyCampaign>> GetActiveCampaignsAsync(Guid? restaurantId = null)
    {
        var now = DateTime.UtcNow;
        var query = _context.LoyaltyCampaigns
            .Where(c => c.IsActive && c.StartDate <= now && c.EndDate >= now);

        if (restaurantId.HasValue)
            query = query.Where(c => c.RestaurantId == restaurantId.Value);

        return await query.OrderByDescending(c => c.CreatedAt).ToListAsync();
    }

    public async Task<LoyaltyCampaign?> GetActiveCampaignForRestaurantAsync(Guid restaurantId)
    {
        var now = DateTime.UtcNow;
        return await _context.LoyaltyCampaigns
            .Where(c => c.IsActive && c.RestaurantId == restaurantId && c.StartDate <= now && c.EndDate >= now)
            .FirstOrDefaultAsync();
    }

    public async Task<int> GetUserCheckInCountAsync(Guid userId)
    {
        return await _context.CheckIns
            .CountAsync(c => c.UserId == userId && c.IsValidated);
    }

    public async Task<int> GetUserReviewCountAsync(Guid userId)
    {
        return await _context.Reviews
            .CountAsync(r => r.UserId == userId);
    }
}
