using OndeComer.Application.DTOs.Dish;

namespace OndeComer.Application.Interfaces;

public interface IDishService
{
    Task<DishDto> CreateAsync(Guid restaurantId, Guid requesterId, CreateDishRequest request, CancellationToken ct = default);
    Task<DishDto> UpdateAsync(Guid dishId, Guid requesterId, UpdateDishRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid dishId, Guid requesterId, CancellationToken ct = default);
    Task<IEnumerable<DishDto>> GetByRestaurantAsync(Guid restaurantId, bool onlyAvailable = false, CancellationToken ct = default);
    Task<DishDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<DishFeedDto>> GetFeedAsync(int page, int pageSize, CancellationToken ct = default);
    Task<int> DeleteExpiredInactiveAsync(CancellationToken ct = default);
}
