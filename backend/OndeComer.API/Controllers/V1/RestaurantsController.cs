using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Restaurant;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/restaurants")]
public class RestaurantsController : ControllerBase
{
    private readonly IRestaurantService _restaurantService;
    private readonly IDishService _dishService;

    public RestaurantsController(IRestaurantService restaurantService, IDishService dishService)
    {
        _restaurantService = restaurantService;
        _dishService = dishService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] string? category,
        [FromQuery] string? city,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var filter = new RestaurantFilterRequest(search, category, city ?? "Salvador", page, pageSize);
        var result = await _restaurantService.GetPagedAsync(filter, ct);
        return Ok(result);
    }

    /// <summary>
    /// Advanced search with spatial distance, price range, rating, and opening-hours filters.
    /// Endpoint: GET /api/v1/restaurants/search
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] RestaurantSearchRequest request, CancellationToken ct)
    {
        var result = await _restaurantService.SearchAsync(request, ct);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var restaurant = await _restaurantService.GetByIdAsync(id, ct);
        if (restaurant is null) return NotFound();
        return Ok(restaurant);
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetMine(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var restaurant = await _restaurantService.GetByOwnerIdAsync(userId, ct);
        if (restaurant is null) return NotFound();
        return Ok(restaurant);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CreateRestaurantRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var restaurant = await _restaurantService.CreateAsync(userId, request, ct);
        return CreatedAtAction(nameof(GetById), new { id = restaurant.Id }, restaurant);
    }

    [HttpPut("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateRestaurantRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var restaurant = await _restaurantService.UpdateAsync(id, userId, request, ct);
        return Ok(restaurant);
    }

    [HttpGet("{id:guid}/dishes")]
    public async Task<IActionResult> GetDishes(Guid id, [FromQuery] bool onlyAvailable = true, CancellationToken ct = default)
    {
        var dishes = await _dishService.GetByRestaurantAsync(id, onlyAvailable, ct);
        return Ok(dishes);
    }
}
