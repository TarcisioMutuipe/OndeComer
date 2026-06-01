using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface ICommentRepository
{
    Task AddAsync(Comment comment, CancellationToken ct = default);
    Task<Comment?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<Comment>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default);
    Task<IEnumerable<Comment>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default);
    void Delete(Comment comment);
}
