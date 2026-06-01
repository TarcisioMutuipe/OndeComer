using OndeComer.Application.DTOs.Favorites;

namespace OndeComer.Application.Interfaces;

public interface IFavoriteService
{
    /// <summary>
    /// Adiciona ou remove o favorito (toggle). Retorna true se foi adicionado, false se removido.
    /// </summary>
    Task<(bool Added, FavoriteDto? Favorite)> ToggleAsync(Guid userId, ToggleFavoriteRequest request, CancellationToken ct = default);
    Task<IEnumerable<FavoriteDto>> GetByUserAsync(Guid userId, CancellationToken ct = default);
    Task<bool> IsFavoritedAsync(Guid userId, Guid? restaurantId, Guid? dishId, CancellationToken ct = default);
}
