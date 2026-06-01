using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IDishRepository
{
    Task<Dish?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<Dish>> GetByRestaurantIdAsync(Guid restaurantId, bool onlyAvailable = false, CancellationToken ct = default);
    Task AddAsync(Dish dish, CancellationToken ct = default);
    Task<bool> ExistsByNameAsync(Guid restaurantId, string name, Guid? excludeId, CancellationToken ct = default);
    void Update(Dish dish);
    void Delete(Dish dish);
}
