using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Wishlists;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Application.Services;

public class WishlistService : IWishlistService
{
    private readonly IUnitOfWork _uow;
    public WishlistService(IUnitOfWork uow) => _uow = uow;

    public async Task<IEnumerable<WishlistDto>> GetByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var list = await _uow.Wishlists.GetByUserAsync(userId, ct);
        return list.Select(w => ToDto(w, includeItems: false));
    }

    public async Task<WishlistDto?> GetByIdAsync(Guid id, Guid requesterId, CancellationToken ct = default)
    {
        var w = await _uow.Wishlists.GetByIdAsync(id, ct);
        if (w is null) return null;
        if (w.UserId != requesterId && !w.IsPublic)
            throw new ForbiddenException("Esta lista é privada.");
        return ToDto(w, includeItems: true);
    }

    public async Task<WishlistDto?> GetPublicByTokenAsync(string shareToken, CancellationToken ct = default)
    {
        var w = await _uow.Wishlists.GetByShareTokenAsync(shareToken, ct);
        return w is null ? null : ToDto(w, includeItems: true);
    }

    public async Task<WishlistDto> CreateAsync(Guid userId, CreateWishlistRequest request, CancellationToken ct = default)
    {
        var wishlist = new Wishlist
        {
            UserId = userId,
            Name = request.Name,
            Description = request.Description,
            IsPublic = request.IsPublic,
        };

        if (request.IsPublic)
            wishlist.ShareToken = await GenerateUniqueTokenAsync(ct);

        await _uow.Wishlists.AddAsync(wishlist, ct);
        await _uow.CommitAsync(ct);
        return ToDto(wishlist, includeItems: true);
    }

    public async Task<WishlistDto> UpdateAsync(Guid id, Guid userId, UpdateWishlistRequest request, CancellationToken ct = default)
    {
        var w = await _uow.Wishlists.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("Lista não encontrada.");
        if (w.UserId != userId)
            throw new ForbiddenException("Você não tem permissão para editar esta lista.");

        if (request.Name is not null) w.Name = request.Name;
        if (request.Description is not null) w.Description = request.Description;
        if (request.IsPublic.HasValue)
        {
            if (request.IsPublic.Value && !w.IsPublic)
                w.ShareToken ??= await GenerateUniqueTokenAsync(ct);
            w.IsPublic = request.IsPublic.Value;
        }
        w.UpdatedAt = DateTime.UtcNow;

        _uow.Wishlists.Update(w);
        await _uow.CommitAsync(ct);
        return ToDto(w, includeItems: true);
    }

    public async Task DeleteAsync(Guid id, Guid userId, CancellationToken ct = default)
    {
        var w = await _uow.Wishlists.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("Lista não encontrada.");
        if (w.UserId != userId)
            throw new ForbiddenException("Você não tem permissão para excluir esta lista.");
        _uow.Wishlists.Delete(w);
        await _uow.CommitAsync(ct);
    }

    public async Task<string> GenerateShareTokenAsync(Guid id, Guid userId, CancellationToken ct = default)
    {
        var w = await _uow.Wishlists.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("Lista não encontrada.");
        if (w.UserId != userId)
            throw new ForbiddenException("Você não tem permissão para compartilhar esta lista.");

        if (w.ShareToken is null)
            w.ShareToken = await GenerateUniqueTokenAsync(ct);

        w.IsPublic = true;
        w.UpdatedAt = DateTime.UtcNow;
        _uow.Wishlists.Update(w);
        await _uow.CommitAsync(ct);
        return w.ShareToken;
    }

    public async Task<WishlistItemDto> AddItemAsync(Guid wishlistId, Guid userId, AddWishlistItemRequest request, CancellationToken ct = default)
    {
        var w = await _uow.Wishlists.GetByIdAsync(wishlistId, ct)
            ?? throw new NotFoundException("Lista não encontrada.");
        if (w.UserId != userId)
            throw new ForbiddenException("Você não tem permissão para editar esta lista.");

        if (request.RestaurantId is null && request.DishId is null)
            throw new AppException("Informe um restaurante ou prato para adicionar.", 400);
        if (request.RestaurantId is not null && request.DishId is not null)
            throw new AppException("Informe apenas restaurante OU prato, não ambos.", 400);

        if (await _uow.WishlistItems.ExistsAsync(wishlistId, request.RestaurantId, request.DishId, ct))
            throw new ConflictException("Este item já está na lista.");

        var item = new WishlistItem
        {
            WishlistId = wishlistId,
            RestaurantId = request.RestaurantId,
            DishId = request.DishId,
            Note = request.Note,
        };
        await _uow.WishlistItems.AddAsync(item, ct);

        w.UpdatedAt = DateTime.UtcNow;
        _uow.Wishlists.Update(w);
        await _uow.CommitAsync(ct);

        return new WishlistItemDto(
            item.Id, item.WishlistId,
            item.RestaurantId, null, null,
            item.DishId, null, null,
            item.Note, item.CreatedAt
        );
    }

    public async Task RemoveItemAsync(Guid itemId, Guid userId, CancellationToken ct = default)
    {
        var item = await _uow.WishlistItems.GetByIdAsync(itemId, ct)
            ?? throw new NotFoundException("Item não encontrado.");
        var w = await _uow.Wishlists.GetByIdAsync(item.WishlistId, ct);
        if (w?.UserId != userId)
            throw new ForbiddenException("Você não tem permissão para editar esta lista.");
        _uow.WishlistItems.Delete(item);
        await _uow.CommitAsync(ct);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private async Task<string> GenerateUniqueTokenAsync(CancellationToken ct)
    {
        string token;
        do
        {
            token = Convert.ToBase64String(Guid.NewGuid().ToByteArray())
                .Replace("+", "-").Replace("/", "_").Replace("=", "")
                .Substring(0, 16);
        } while (await _uow.Wishlists.ShareTokenExistsAsync(token, ct));
        return token;
    }

    private static WishlistDto ToDto(Wishlist w, bool includeItems)
    {
        var items = includeItems
            ? w.Items.Select(ItemToDto).ToList()
            : new List<WishlistItemDto>();

        return new WishlistDto(
            w.Id, w.UserId, w.Name, w.Description,
            w.IsPublic, w.ShareToken,
            w.ShareToken is not null ? $"/wishlists/public/{w.ShareToken}" : null,
            w.Items.Count, items,
            w.CreatedAt, w.UpdatedAt
        );
    }

    private static WishlistItemDto ItemToDto(WishlistItem i) => new(
        i.Id, i.WishlistId,
        i.RestaurantId, i.Restaurant?.Name, i.Restaurant?.LogoUrl,
        i.DishId, i.Dish?.Name, i.Dish?.ImageUrl,
        i.Note, i.CreatedAt
    );
}
