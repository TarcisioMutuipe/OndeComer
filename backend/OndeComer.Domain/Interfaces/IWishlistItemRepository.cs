using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IWishlistItemRepository
{
    Task<WishlistItem?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<bool> ExistsAsync(Guid wishlistId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default);
    Task AddAsync(WishlistItem item, CancellationToken ct = default);
    void Delete(WishlistItem item);
}
