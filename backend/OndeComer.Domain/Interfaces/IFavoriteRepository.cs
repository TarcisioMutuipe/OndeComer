using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IFavoriteRepository
{
    Task<Favorite?> GetAsync(Guid userId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default);
    Task<IEnumerable<Favorite>> GetByUserAsync(Guid userId, CancellationToken ct = default);
    Task<bool> ExistsAsync(Guid userId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default);
    Task AddAsync(Favorite favorite, CancellationToken ct = default);
    void Delete(Favorite favorite);
}
