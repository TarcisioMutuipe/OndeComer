using OndeComer.Application.Common;
using OndeComer.Application.DTOs.Restaurant;

namespace OndeComer.Application.Interfaces;

public interface IRestaurantService
{
    Task<RestaurantDto> CreateAsync(Guid ownerId, CreateRestaurantRequest request, CancellationToken ct = default);
    Task<RestaurantDto> UpdateAsync(Guid restaurantId, Guid requesterId, UpdateRestaurantRequest request, CancellationToken ct = default);
    Task<RestaurantDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<RestaurantDto?> GetByOwnerIdAsync(Guid ownerId, CancellationToken ct = default);
    Task<IEnumerable<RestaurantDto>> GetAllActiveAsync(CancellationToken ct = default);
    Task<PagedResult<RestaurantDto>> GetPagedAsync(RestaurantFilterRequest filter, CancellationToken ct = default);
    Task<PagedResult<RestaurantSearchResultDto>> SearchAsync(RestaurantSearchRequest request, CancellationToken ct = default);
}
