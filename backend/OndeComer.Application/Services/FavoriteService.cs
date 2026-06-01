using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Favorites;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Application.Services;

public class FavoriteService : IFavoriteService
{
    private readonly IUnitOfWork _uow;
    public FavoriteService(IUnitOfWork uow) => _uow = uow;

    public async Task<(bool Added, FavoriteDto? Favorite)> ToggleAsync(
        Guid userId, ToggleFavoriteRequest request, CancellationToken ct = default)
    {
        if (request.RestaurantId is null && request.DishId is null)
            throw new AppException("Informe um restaurante ou prato para favoritar.", 400);
        if (request.RestaurantId is not null && request.DishId is not null)
            throw new AppException("Informe apenas restaurante OU prato, não ambos.", 400);

        var existing = await _uow.Favorites.GetAsync(userId, request.RestaurantId, request.DishId, ct);
        if (existing is not null)
        {
            _uow.Favorites.Delete(existing);
            await _uow.CommitAsync(ct);
            return (false, null);
        }

        var favorite = new Favorite
        {
            UserId = userId,
            RestaurantId = request.RestaurantId,
            DishId = request.DishId,
        };
        await _uow.Favorites.AddAsync(favorite, ct);
        await _uow.CommitAsync(ct);

        // Recarregar com navegações para montar o DTO
        var loaded = await _uow.Favorites.GetAsync(userId, request.RestaurantId, request.DishId, ct);
        return (true, loaded is null ? null : ToDto(loaded));
    }

    public async Task<IEnumerable<FavoriteDto>> GetByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var list = await _uow.Favorites.GetByUserAsync(userId, ct);
        return list.Select(ToDto);
    }

    public Task<bool> IsFavoritedAsync(Guid userId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default)
        => _uow.Favorites.ExistsAsync(userId, restaurantId, dishId, ct);

    private static FavoriteDto ToDto(Favorite f) => new(
        f.Id, f.UserId,
        f.RestaurantId, f.Restaurant?.Name, f.Restaurant?.LogoUrl,
        f.DishId, f.Dish?.Name, f.Dish?.ImageUrl,
        f.CreatedAt
    );
}
