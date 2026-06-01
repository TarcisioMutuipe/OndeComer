using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IPromotionRepository
{
    Task<IEnumerable<Promotion>> GetActiveAsync(int page, int pageSize, CancellationToken ct = default);
    Task<IEnumerable<Promotion>> GetByRestaurantAsync(Guid restaurantId, CancellationToken ct = default);
    Task AddAsync(Promotion promotion, CancellationToken ct = default);
    Task<Promotion?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<bool> BelongsToRestaurantAsync(Guid promotionId, Guid restaurantId, CancellationToken ct = default);
}
