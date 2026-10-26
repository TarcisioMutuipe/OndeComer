using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Admin;
using OndeComer.Application.DTOs.Dish;
using OndeComer.Application.DTOs.Moderation;
using OndeComer.Application.DTOs.Promotion;
using OndeComer.Application.DTOs.Restaurant;
using OndeComer.Application.Common;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Enums;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/admin")]
[Authorize(Policy = "AdminOnly")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;
    private readonly IModerationService _moderationService;
    private readonly IDishService _dishService;
    private readonly IRestaurantService _restaurantService;
    private readonly ICommentService _commentService;
    private readonly IPromotionService _promotionService;

    public AdminController(
        IAdminService adminService,
        IModerationService moderationService,
        IDishService dishService,
        IRestaurantService restaurantService,
        ICommentService commentService,
        IPromotionService promotionService)
    {
        _adminService = adminService;
        _moderationService = moderationService;
        _dishService = dishService;
        _restaurantService = restaurantService;
        _commentService = commentService;
        _promotionService = promotionService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    [HttpGet("dashboard")]
    public async Task<ActionResult<AdminDashboardDto>> GetDashboard()
        => Ok(await _adminService.GetDashboardAsync());

    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<AdminUserDto>>> GetUsers(
        [FromQuery] string? search, [FromQuery] string? profileType,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => Ok(await _adminService.GetUsersAsync(search, profileType, page, pageSize));

    [HttpPut("users/{userId:guid}")]
    public async Task<ActionResult<AdminUserDto>> UpdateUser(Guid userId, [FromBody] AdminUpdateUserRequest request)
        => Ok(await _adminService.UpdateUserAsync(userId, request));

    [HttpDelete("users/{userId:guid}")]
    public async Task<IActionResult> DeleteUser(Guid userId)
    {
        await _adminService.DeleteUserAsync(userId);
        return NoContent();
    }

    [HttpGet("restaurants")]
    public async Task<ActionResult<IEnumerable<AdminRestaurantDto>>> GetRestaurants(
        [FromQuery] string? search, [FromQuery] string? category,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => Ok(await _adminService.GetRestaurantsAsync(search, category, page, pageSize));

    [HttpPut("restaurants/{restaurantId:guid}")]
    public async Task<ActionResult<AdminRestaurantDto>> UpdateRestaurant(Guid restaurantId, [FromBody] AdminUpdateRestaurantRequest request)
        => Ok(await _adminService.UpdateRestaurantAsync(restaurantId, request));

    [HttpDelete("restaurants/{restaurantId:guid}")]
    public async Task<IActionResult> DeleteRestaurant(Guid restaurantId)
    {
        await _adminService.DeleteRestaurantAsync(restaurantId);
        return NoContent();
    }

    [HttpGet("moderation/logs")]
    public async Task<ActionResult<IEnumerable<ModerationLogDto>>> GetModerationLogs(
        [FromQuery] string? result, [FromQuery] string? entityType,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        => Ok(await _moderationService.GetLogsAsync(result, entityType, page, pageSize));

    [HttpPost("moderation/logs/{logId:guid}/review")]
    public async Task<ActionResult<ModerationLogDto>> ReviewModeration(Guid logId, [FromBody] ReviewModerationRequest request)
        => Ok(await _moderationService.ReviewLogAsync(logId, GetCurrentUserId(), request.Decision));

    [HttpGet("users/{userId:guid}/export")]
    public async Task<IActionResult> ExportUserData(Guid userId, [FromQuery] string format = "json")
    {
        var data = await _adminService.ExportUserDataAsync(userId, format);
        var contentType = format.Equals("csv", StringComparison.OrdinalIgnoreCase) ? "text/csv" : "application/json";
        var ext = format.Equals("csv", StringComparison.OrdinalIgnoreCase) ? "csv" : "json";
        return File(data, contentType, $"user_{userId}_export.{ext}");
    }

    [HttpPost("restaurants/{restaurantId:guid}/dishes")]
    public async Task<IActionResult> CreateDish(Guid restaurantId, [FromBody] CreateDishRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var dish = await _dishService.CreateAsync(restaurantId, userId, request, ct);
        return CreatedAtAction(null, new { id = dish.Id }, dish);
    }

    [HttpPut("dishes/{dishId:guid}")]
    public async Task<IActionResult> UpdateDish(Guid dishId, [FromBody] UpdateDishRequest request, CancellationToken ct)
        => Ok(await _dishService.UpdateAsync(dishId, GetCurrentUserId(), request, ct));

    [HttpDelete("dishes/{dishId:guid}")]
    public async Task<IActionResult> DeleteDish(Guid dishId, CancellationToken ct)
    {
        await _dishService.DeleteAsync(dishId, GetCurrentUserId(), ct);
        return NoContent();
    }

    [HttpPut("restaurants/{restaurantId:guid}/full")]
    public async Task<IActionResult> FullUpdateRestaurant(Guid restaurantId, [FromBody] UpdateRestaurantRequest request, CancellationToken ct)
        => Ok(await _restaurantService.UpdateAsync(restaurantId, GetCurrentUserId(), request, ct));

    [HttpDelete("comments/{commentId:guid}")]
    public async Task<IActionResult> DeleteComment(Guid commentId, CancellationToken ct)
    {
        await _commentService.DeleteAsync(commentId, ct);
        return NoContent();
    }

    [HttpGet("promotions/settings")]
    public async Task<ActionResult<PromotionSettingsDto>> GetPromotionSettings(CancellationToken ct)
        => Ok(await _promotionService.GetSettingsAsync(ct));

    [HttpPut("promotions/settings")]
    public async Task<ActionResult<PromotionSettingsDto>> UpdatePromotionSettings([FromBody] UpdatePromotionSettingsRequest request, CancellationToken ct)
        => Ok(await _promotionService.UpdateSettingsAsync(request, ct));

    [HttpGet("promotions/summary")]
    public async Task<ActionResult<PromotionSummaryDto>> GetPromotionSummary(CancellationToken ct)
        => Ok(await _promotionService.GetSummaryAsync(ct));

    [HttpGet("promotions/tickets")]
    public async Task<ActionResult<PagedResult<PromotionTicketAdminDto>>> GetPromotionTickets(
        [FromQuery] Guid? restaurantId,
        [FromQuery] string? status,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        PromotionTicketStatus? parsedStatus = Enum.TryParse<PromotionTicketStatus>(status, true, out var parsed)
            ? parsed
            : null;
        return Ok(await _promotionService.GetAdminTicketsAsync(restaurantId, parsedStatus, from, to, page, pageSize, ct));
    }

    [HttpGet("promotions/tickets/summary")]
    public async Task<ActionResult<PromotionTicketsAdminSummaryDto>> GetPromotionTicketsSummary(
        [FromQuery] Guid? restaurantId,
        [FromQuery] string? status,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        CancellationToken ct = default)
    {
        PromotionTicketStatus? parsedStatus = Enum.TryParse<PromotionTicketStatus>(status, true, out var parsed)
            ? parsed
            : null;
        return Ok(await _promotionService.GetAdminTicketsSummaryAsync(restaurantId, parsedStatus, from, to, ct));
    }
}
