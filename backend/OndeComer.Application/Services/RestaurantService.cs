using OndeComer.Application.Common;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Restaurant;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Domain.Interfaces;
using System.Text.Json;

namespace OndeComer.Application.Services;

public class RestaurantService : IRestaurantService
{
    private readonly IUnitOfWork _uow;

    public RestaurantService(IUnitOfWork uow) => _uow = uow;

    public async Task<RestaurantDto> CreateAsync(Guid ownerId, CreateRestaurantRequest request, CancellationToken ct = default)
    {
        if (await _uow.Restaurants.ExistsByOwnerIdAsync(ownerId, ct))
            throw new ConflictException("Este usuário já possui um restaurante cadastrado.");

        var restaurant = new Restaurant
        {
            OwnerUserId = ownerId,
            Name = request.Name,
            Description = request.Description,
            Address = request.Address,
            City = request.City ?? "Salvador",
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Category = request.Category,
            LogoUrl = request.LogoUrl,
            CoverUrl = request.CoverUrl,
            InstagramUrl = request.InstagramUrl,
            YouTubeVideoUrl = request.YouTubeVideoUrl,
            OpeningHours = request.OpeningHours ?? "",
        };

        await _uow.Restaurants.AddAsync(restaurant, ct);
        await _uow.CommitAsync(ct);
        return ToDto(restaurant);
    }

    public async Task<RestaurantDto> UpdateAsync(Guid restaurantId, Guid requesterId, UpdateRestaurantRequest request, CancellationToken ct = default)
    {
        var restaurant = await _uow.Restaurants.GetByIdAsync(restaurantId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        var requester = await _uow.Users.GetByIdAsync(requesterId, ct);
        if (requester?.ProfileType != ProfileType.Admin && restaurant.OwnerUserId != requesterId)
            throw new ForbiddenException("Você não tem permissão para editar este restaurante.");

        if (request.Name is not null) restaurant.Name = request.Name;
        if (request.Description is not null) restaurant.Description = request.Description;
        if (request.Address is not null) restaurant.Address = request.Address;
        if (request.City is not null) restaurant.City = request.City;
        if (request.Latitude.HasValue) restaurant.Latitude = request.Latitude.Value;
        if (request.Longitude.HasValue) restaurant.Longitude = request.Longitude.Value;
        if (request.Category is not null) restaurant.Category = request.Category;
        if (request.LogoUrl is not null) restaurant.LogoUrl = request.LogoUrl;
        if (request.CoverUrl is not null) restaurant.CoverUrl = request.CoverUrl;
        if (request.InstagramUrl is not null) restaurant.InstagramUrl = request.InstagramUrl;
        if (request.YouTubeVideoUrl is not null) restaurant.YouTubeVideoUrl = request.YouTubeVideoUrl;
        if (request.OpeningHours is not null) restaurant.OpeningHours = request.OpeningHours;
        if (request.IsActive.HasValue) restaurant.IsActive = request.IsActive.Value;

        _uow.Restaurants.Update(restaurant);
        await _uow.CommitAsync(ct);
        return ToDto(restaurant);
    }

    public async Task<RestaurantDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var r = await _uow.Restaurants.GetByIdAsync(id, ct);
        return r is null ? null : ToDto(r);
    }

    public async Task<RestaurantDto?> GetByOwnerIdAsync(Guid ownerId, CancellationToken ct = default)
    {
        var r = await _uow.Restaurants.GetByOwnerIdAsync(ownerId, ct);
        return r is null ? null : ToDto(r);
    }

    public async Task<IEnumerable<RestaurantDto>> GetAllActiveAsync(CancellationToken ct = default)
    {
        var list = await _uow.Restaurants.GetAllActiveAsync(ct);
        return list.Select(ToDto);
    }

    public async Task<PagedResult<RestaurantDto>> GetPagedAsync(RestaurantFilterRequest filter, CancellationToken ct = default)
    {
        var pageSize = Math.Clamp(filter.PageSize, 1, 50);
        var page = Math.Max(filter.Page, 1);
        var (items, total) = await _uow.Restaurants.GetPagedAsync(
            filter.Search, filter.Category, filter.City ?? "Salvador",
            page, pageSize, ct);
        return new PagedResult<RestaurantDto>(items.Select(ToDto), page, pageSize, total);
    }

    private static RestaurantDto ToDto(Restaurant r) => new(
        r.Id, r.OwnerUserId, r.Name, r.Description, r.Address, r.City,
        r.Latitude, r.Longitude, r.Category, r.LogoUrl, r.CoverUrl, r.InstagramUrl,
        r.YouTubeVideoUrl, r.IsActive, r.OpeningHours, r.Dishes?.Count ?? 0, r.CreatedAt
    );

    // ─── Advanced Search ────────────────────────────────────────────────────

    public async Task<PagedResult<RestaurantSearchResultDto>> SearchAsync(
        RestaurantSearchRequest request, CancellationToken ct = default)
    {
        var pageSize = Math.Clamp(request.PageSize, 1, 50);
        var page = Math.Max(request.Page, 1);

        var candidates = await _uow.Restaurants.SearchAdvancedAsync(
            request.Query, request.Category,
            request.MinPrice, request.MaxPrice, request.MinRating,
            request.Lat, request.Lng, request.Radius,
            ct);

        // Compute derived fields and apply remaining in-memory filters
        var results = candidates.Select(r =>
        {
            double? distance = (request.Lat.HasValue && request.Lng.HasValue)
                ? HaversineKm(request.Lat.Value, request.Lng.Value, r.Latitude, r.Longitude)
                : null;

            double avgRating = r.Dishes?.Where(d => d.IsActive && d.RatingCount > 0)
                .DefaultIfEmpty()
                .Average(d => d?.RatingAverage ?? 0) ?? 0;

            decimal? minPrice = r.Dishes?.Where(d => d.IsActive)
                .Select(d => d.Price)
                .DefaultIfEmpty()
                .Min();
            if (minPrice == 0) minPrice = null;

            bool isOpen = IsCurrentlyOpen(r.OpeningHours);

            return (Restaurant: r, Distance: distance, AvgRating: avgRating,
                    MinPrice: minPrice, IsOpen: isOpen);
        }).ToList();

        // Exact radius filter (Haversine is more accurate than bounding box)
        if (request.Lat.HasValue && request.Lng.HasValue && request.Radius.HasValue)
            results = results.Where(x => x.Distance <= request.Radius.Value).ToList();

        // isOpenNow filter
        if (request.IsOpenNow == true)
            results = results.Where(x => x.IsOpen).ToList();

        // Sort
        var sortDesc = request.SortOrder.Equals("desc", StringComparison.OrdinalIgnoreCase);
        results = request.SortBy.ToLower() switch
        {
            "distance" when !sortDesc =>
                results.OrderBy(x => x.Distance ?? double.MaxValue).ToList(),
            "distance" =>
                results.OrderByDescending(x => x.Distance ?? 0).ToList(),
            "rating" when !sortDesc =>
                results.OrderByDescending(x => x.AvgRating).ToList(),
            "rating" =>
                results.OrderBy(x => x.AvgRating).ToList(),
            "name" when sortDesc =>
                results.OrderByDescending(x => x.Restaurant.Name).ToList(),
            _ =>
                results.OrderBy(x => x.Restaurant.Name).ToList(),
        };

        var total = results.Count;
        var paged = results.Skip((page - 1) * pageSize).Take(pageSize);

        var dtos = paged.Select(x => new RestaurantSearchResultDto(
            x.Restaurant.Id, x.Restaurant.OwnerUserId, x.Restaurant.Name,
            x.Restaurant.Description, x.Restaurant.Address, x.Restaurant.City,
            x.Restaurant.Latitude, x.Restaurant.Longitude, x.Restaurant.Category,
            x.Restaurant.LogoUrl, x.Restaurant.CoverUrl, x.Restaurant.InstagramUrl,
            x.Restaurant.YouTubeVideoUrl, x.Restaurant.IsActive, x.Restaurant.OpeningHours,
            x.Restaurant.Dishes?.Count ?? 0, x.Restaurant.CreatedAt,
            x.Distance.HasValue ? Math.Round(x.Distance.Value, 2) : null,
            Math.Round(x.AvgRating, 2),
            x.IsOpen,
            x.MinPrice
        ));

        return new PagedResult<RestaurantSearchResultDto>(dtos, page, pageSize, total);
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    /// <summary>Haversine great-circle distance in km.</summary>
    private static double HaversineKm(double lat1, double lng1, double lat2, double lng2)
    {
        const double R = 6371.0;
        var dLat = ToRad(lat2 - lat1);
        var dLng = ToRad(lng2 - lng1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
              + Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2))
              * Math.Sin(dLng / 2) * Math.Sin(dLng / 2);
        return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static double ToRad(double deg) => deg * Math.PI / 180.0;

    /// <summary>
    /// Determines if a restaurant is currently open based on its OpeningHours JSON.
    /// Format: {"monday":{"open":"11:00","close":"22:00"}, "tuesday":null, ...}
    /// Uses Brazil Standard Time (UTC-3, BRT) — DST abolished in 2019.
    /// Returns false when hours are unknown.
    /// </summary>
    private static bool IsCurrentlyOpen(string openingHoursJson)
    {
        if (string.IsNullOrWhiteSpace(openingHoursJson) || openingHoursJson == "{}")
            return false;

        try
        {
            var nowBrt = DateTime.UtcNow.AddHours(-3);
            var dayName = nowBrt.DayOfWeek.ToString().ToLower();

            using var doc = JsonDocument.Parse(openingHoursJson);
            var root = doc.RootElement;

            if (!root.TryGetProperty(dayName, out var dayEl) ||
                dayEl.ValueKind == JsonValueKind.Null)
                return false;

            if (!dayEl.TryGetProperty("open", out var openEl) ||
                !dayEl.TryGetProperty("close", out var closeEl))
                return false;

            if (!TimeSpan.TryParse(openEl.GetString(), out var open) ||
                !TimeSpan.TryParse(closeEl.GetString(), out var close))
                return false;

            var current = nowBrt.TimeOfDay;

            // Handle overnight (e.g. open 22:00 close 02:00)
            return close < open
                ? current >= open || current <= close
                : current >= open && current <= close;
        }
        catch
        {
            return false;
        }
    }
}
