using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface ICheckInRepository
{
    Task<CheckIn> AddAsync(CheckIn checkIn);
    Task<CheckIn?> GetLastCheckInAsync(Guid userId, Guid restaurantId);
    Task<IEnumerable<CheckIn>> GetByUserAsync(Guid userId, int page, int pageSize);
    Task<IEnumerable<CheckIn>> GetByRestaurantAsync(Guid restaurantId, int page, int pageSize);
    Task<int> GetTotalPointsByUserAsync(Guid userId);
    Task<int> GetCheckInCountTodayAsync(Guid userId, Guid restaurantId);
}
