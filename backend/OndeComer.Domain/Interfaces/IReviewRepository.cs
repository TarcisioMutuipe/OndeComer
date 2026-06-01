using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IReviewRepository
{
    Task AddAsync(Review review, CancellationToken ct = default);
    Task<Review?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<bool> ExistsAsync(Guid dishId, Guid userId, CancellationToken ct = default);
    Task<IEnumerable<Review>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default);
    Task<IEnumerable<Review>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default);
    Task<(double Average, int Count)> GetRatingStatsAsync(Guid dishId, CancellationToken ct = default);
}
