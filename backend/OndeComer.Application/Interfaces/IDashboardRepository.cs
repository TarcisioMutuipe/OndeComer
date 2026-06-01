using OndeComer.Application.DTOs.Dashboard;

namespace OndeComer.Application.Interfaces;

public interface IDashboardRepository
{
    Task<DashboardOverviewDto> GetOverviewAsync(Guid restaurantId, CancellationToken ct = default);
    Task<List<DishMetricDto>> GetDishMetricsAsync(Guid restaurantId, CancellationToken ct = default);
    Task<List<HourMetricDto>> GetHourMetricsAsync(Guid restaurantId, CancellationToken ct = default);
    Task<CommentMetricDto> GetCommentMetricsAsync(Guid restaurantId, CancellationToken ct = default);
}
