using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IWishlistRepository
{
    Task<Wishlist?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Wishlist?> GetByShareTokenAsync(string shareToken, CancellationToken ct = default);
    Task<IEnumerable<Wishlist>> GetByUserAsync(Guid userId, CancellationToken ct = default);
    Task<bool> ShareTokenExistsAsync(string token, CancellationToken ct = default);
    Task AddAsync(Wishlist wishlist, CancellationToken ct = default);
    void Update(Wishlist wishlist);
    void Delete(Wishlist wishlist);
}
