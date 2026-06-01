using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;
using OndeComer.Application.DTOs.Dashboard;
using OndeComer.Application.Interfaces;

namespace OndeComer.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repo;
    private readonly IDistributedCache _cache;
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(15);

    public DashboardService(IDashboardRepository repo, IDistributedCache cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public async Task<DashboardOverviewDto> GetOverviewAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var key = $"dashboard:overview:{restaurantId}";
        return await GetOrSetCacheAsync(key, () => _repo.GetOverviewAsync(restaurantId, ct), ct);
    }

    public async Task<List<DishMetricDto>> GetDishMetricsAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var key = $"dashboard:dishes:{restaurantId}";
        return await GetOrSetCacheAsync(key, () => _repo.GetDishMetricsAsync(restaurantId, ct), ct);
    }

    public async Task<List<HourMetricDto>> GetHourMetricsAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var key = $"dashboard:hours:{restaurantId}";
        return await GetOrSetCacheAsync(key, () => _repo.GetHourMetricsAsync(restaurantId, ct), ct);
    }

    public async Task<CommentMetricDto> GetCommentMetricsAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var key = $"dashboard:comments:{restaurantId}";
        return await GetOrSetCacheAsync(key, () => _repo.GetCommentMetricsAsync(restaurantId, ct), ct);
    }

    private async Task<T> GetOrSetCacheAsync<T>(string key, Func<Task<T>> factory, CancellationToken ct)
    {
        var cached = await _cache.GetStringAsync(key, ct);
        if (cached != null)
        {
            return JsonSerializer.Deserialize<T>(cached)!;
        }

        var data = await factory();
        var json = JsonSerializer.Serialize(data);
        await _cache.SetStringAsync(key, json, new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = CacheDuration
        }, ct);

        return data;
    }
}
