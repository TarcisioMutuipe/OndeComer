using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Admin;
using OndeComer.Application.DTOs.Dish;
using OndeComer.Application.DTOs.Moderation;
using OndeComer.Application.DTOs.Restaurant;
using OndeComer.Application.Interfaces;
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

    public AdminController(
        IAdminService adminService,
        IModerationService moderationService,
        IDishService dishService,
        IRestaurantService restaurantService,
        ICommentService commentService)
    {
        _adminService = adminService;
        _moderationService = moderationService;
        _dishService = dishService;
        _restaurantService = restaurantService;
        _commentService = commentService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    // --- Dashboard ---
    [HttpGet("dashboard")]
    public async Task<ActionResult<AdminDashboardDto>> GetDashboard()
    {
        var result = await _adminService.GetDashboardAsync();
        return Ok(result);
    }

    // --- Users ---
    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<AdminUserDto>>> GetUsers(
        [FromQuery] string? search, [FromQuery] string? profileType,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _adminService.GetUsersAsync(search, profileType, page, pageSize);
        return Ok(result);
    }

    [HttpPut("users/{userId:guid}")]
    public async Task<ActionResult<AdminUserDto>> UpdateUser(Guid userId, [FromBody] AdminUpdateUserRequest request)
    {
        var result = await _adminService.UpdateUserAsync(userId, request);
        return Ok(result);
    }

    [HttpDelete("users/{userId:guid}")]
    public async Task<IActionResult> DeleteUser(Guid userId)
    {
        await _adminService.DeleteUserAsync(userId);
        return NoContent();
    }

    // --- Restaurants ---
    [HttpGet("restaurants")]
    public async Task<ActionResult<IEnumerable<AdminRestaurantDto>>> GetRestaurants(
        [FromQuery] string? search, [FromQuery] string? category,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _adminService.GetRestaurantsAsync(search, category, page, pageSize);
        return Ok(result);
    }

    [HttpPut("restaurants/{restaurantId:guid}")]
    public async Task<ActionResult<AdminRestaurantDto>> UpdateRestaurant(Guid restaurantId, [FromBody] AdminUpdateRestaurantRequest request)
    {
        var result = await _adminService.UpdateRestaurantAsync(restaurantId, request);
        return Ok(result);
    }

    [HttpDelete("restaurants/{restaurantId:guid}")]
    public async Task<IActionResult> DeleteRestaurant(Guid restaurantId)
    {
        await _adminService.DeleteRestaurantAsync(restaurantId);
        return NoContent();
    }

    // --- Moderation Override ---
    [HttpGet("moderation/logs")]
    public async Task<ActionResult<IEnumerable<ModerationLogDto>>> GetModerationLogs(
        [FromQuery] string? result, [FromQuery] string? entityType,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var logs = await _moderationService.GetLogsAsync(result, entityType, page, pageSize);
        return Ok(logs);
    }

    [HttpPost("moderation/logs/{logId:guid}/review")]
    public async Task<ActionResult<ModerationLogDto>> ReviewModeration(Guid logId, [FromBody] ReviewModerationRequest request)
    {
        var userId = GetCurrentUserId();
        var log = await _moderationService.ReviewLogAsync(logId, userId, request.Decision);
        return Ok(log);
    }

    // --- LGPD Export ---
    [HttpGet("users/{userId:guid}/export")]
    public async Task<IActionResult> ExportUserData(Guid userId, [FromQuery] string format = "json")
    {
        var data = await _adminService.ExportUserDataAsync(userId, format);
        var contentType = format.Equals("csv", StringComparison.OrdinalIgnoreCase)
            ? "text/csv" : "application/json";
        var ext = format.Equals("csv", StringComparison.OrdinalIgnoreCase) ? "csv" : "json";
        return File(data, contentType, $"user_{userId}_export.{ext}");
    }

    // --- Dishes (Admin full access) ---
    [HttpPost("restaurants/{restaurantId:guid}/dishes")]
    public async Task<IActionResult> CreateDish(Guid restaurantId, [FromBody] CreateDishRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var dish = await _dishService.CreateAsync(restaurantId, userId, request, ct);
        return CreatedAtAction(null, new { id = dish.Id }, dish);
    }

    [HttpPut("dishes/{dishId:guid}")]
    public async Task<IActionResult> UpdateDish(Guid dishId, [FromBody] UpdateDishRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var dish = await _dishService.UpdateAsync(dishId, userId, request, ct);
        return Ok(dish);
    }

    [HttpDelete("dishes/{dishId:guid}")]
    public async Task<IActionResult> DeleteDish(Guid dishId, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _dishService.DeleteAsync(dishId, userId, ct);
        return NoContent();
    }

    // --- Restaurant full update (Admin can set YouTubeVideoUrl and all fields) ---
    [HttpPut("restaurants/{restaurantId:guid}/full")]
    public async Task<IActionResult> FullUpdateRestaurant(Guid restaurantId, [FromBody] UpdateRestaurantRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var restaurant = await _restaurantService.UpdateAsync(restaurantId, userId, request, ct);
        return Ok(restaurant);
    }

    // --- Comments (Admin can delete any comment) ---
    [HttpDelete("comments/{commentId:guid}")]
    public async Task<IActionResult> DeleteComment(Guid commentId, CancellationToken ct)
    {
        await _commentService.DeleteAsync(commentId, ct);
        return NoContent();
    }
}
