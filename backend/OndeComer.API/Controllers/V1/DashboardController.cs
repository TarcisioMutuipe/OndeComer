using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/restaurants/{restaurantId}/dashboard")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;
    private readonly IRestaurantService _restaurantService;

    public DashboardController(IDashboardService dashboardService, IRestaurantService restaurantService)
    {
        _dashboardService = dashboardService;
        _restaurantService = restaurantService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    [HttpGet("overview")]
    public async Task<IActionResult> GetOverview(Guid restaurantId, CancellationToken ct)
    {
        await EnsureOwnerAsync(restaurantId, ct);
        var result = await _dashboardService.GetOverviewAsync(restaurantId, ct);
        return Ok(result);
    }

    [HttpGet("metrics/dishes")]
    public async Task<IActionResult> GetDishMetrics(Guid restaurantId, CancellationToken ct)
    {
        await EnsureOwnerAsync(restaurantId, ct);
        var result = await _dashboardService.GetDishMetricsAsync(restaurantId, ct);
        return Ok(result);
    }

    [HttpGet("metrics/hours")]
    public async Task<IActionResult> GetHourMetrics(Guid restaurantId, CancellationToken ct)
    {
        await EnsureOwnerAsync(restaurantId, ct);
        var result = await _dashboardService.GetHourMetricsAsync(restaurantId, ct);
        return Ok(result);
    }

    [HttpGet("metrics/comments")]
    public async Task<IActionResult> GetCommentMetrics(Guid restaurantId, CancellationToken ct)
    {
        await EnsureOwnerAsync(restaurantId, ct);
        var result = await _dashboardService.GetCommentMetricsAsync(restaurantId, ct);
        return Ok(result);
    }

    private async Task EnsureOwnerAsync(Guid restaurantId, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var restaurant = await _restaurantService.GetByIdAsync(restaurantId, ct);
        if (restaurant == null || restaurant.OwnerUserId != userId)
            throw new UnauthorizedAccessException("Você não é o dono deste restaurante.");
    }
}
