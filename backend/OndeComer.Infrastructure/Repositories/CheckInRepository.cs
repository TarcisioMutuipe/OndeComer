using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class CheckInRepository : ICheckInRepository
{
    private readonly AppDbContext _context;

    public CheckInRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<CheckIn> AddAsync(CheckIn checkIn)
    {
        _context.CheckIns.Add(checkIn);
        await _context.SaveChangesAsync();
        return checkIn;
    }

    public async Task<CheckIn?> GetLastCheckInAsync(Guid userId, Guid restaurantId)
    {
        return await _context.CheckIns
            .Where(c => c.UserId == userId && c.RestaurantId == restaurantId)
            .OrderByDescending(c => c.CheckInTime)
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<CheckIn>> GetByUserAsync(Guid userId, int page, int pageSize)
    {
        return await _context.CheckIns
            .Include(c => c.Restaurant)
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CheckInTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<IEnumerable<CheckIn>> GetByRestaurantAsync(Guid restaurantId, int page, int pageSize)
    {
        return await _context.CheckIns
            .Include(c => c.User)
            .Where(c => c.RestaurantId == restaurantId)
            .OrderByDescending(c => c.CheckInTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<int> GetTotalPointsByUserAsync(Guid userId)
    {
        return await _context.CheckIns
            .Where(c => c.UserId == userId && c.IsValidated)
            .SumAsync(c => c.PointsAwarded);
    }

    public async Task<int> GetCheckInCountTodayAsync(Guid userId, Guid restaurantId)
    {
        var today = DateTime.UtcNow.Date;
        return await _context.CheckIns
            .CountAsync(c => c.UserId == userId
                          && c.RestaurantId == restaurantId
                          && c.CheckInTime >= today);
    }
}
