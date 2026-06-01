using OndeComer.Application.DTOs.Wishlists;

namespace OndeComer.Application.Interfaces;

public interface IWishlistService
{
    Task<IEnumerable<WishlistDto>> GetByUserAsync(Guid userId, CancellationToken ct = default);
    Task<WishlistDto?> GetByIdAsync(Guid id, Guid requesterId, CancellationToken ct = default);
    Task<WishlistDto?> GetPublicByTokenAsync(string shareToken, CancellationToken ct = default);
    Task<WishlistDto> CreateAsync(Guid userId, CreateWishlistRequest request, CancellationToken ct = default);
    Task<WishlistDto> UpdateAsync(Guid id, Guid userId, UpdateWishlistRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid id, Guid userId, CancellationToken ct = default);
    Task<string> GenerateShareTokenAsync(Guid id, Guid userId, CancellationToken ct = default);
    Task<WishlistItemDto> AddItemAsync(Guid wishlistId, Guid userId, AddWishlistItemRequest request, CancellationToken ct = default);
    Task RemoveItemAsync(Guid itemId, Guid userId, CancellationToken ct = default);
}
