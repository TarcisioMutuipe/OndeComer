using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IRestaurantRepository
{
    Task<Restaurant?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Restaurant?> GetByOwnerIdAsync(Guid ownerId, CancellationToken ct = default);
    Task<IEnumerable<Restaurant>> GetAllActiveAsync(CancellationToken ct = default);
    Task<(IEnumerable<Restaurant> Items, int TotalCount)> GetPagedAsync(
        string? search, string? category, string? city,
        int page, int pageSize, CancellationToken ct = default);
    Task AddAsync(Restaurant restaurant, CancellationToken ct = default);
    void Update(Restaurant restaurant);
    Task<bool> ExistsByOwnerIdAsync(Guid ownerId, CancellationToken ct = default);
    Task<bool> ExistsByNameAndAddressAsync(string name, string address, Guid? excludeId = null, CancellationToken ct = default);

    /// <summary>
    /// Returns active restaurants matching text/category/price/rating and optionally within a
    /// lat/lng bounding box (pre-filter before exact Haversine calculation).
    /// </summary>
    Task<IEnumerable<Restaurant>> SearchAdvancedAsync(
        string? query,
        string? category,
        decimal? minPrice,
        decimal? maxPrice,
        double? minRating,
        double? lat,
        double? lng,
        double? radiusKm,
        CancellationToken ct = default);
}
