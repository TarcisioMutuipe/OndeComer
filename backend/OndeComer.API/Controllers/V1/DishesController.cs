using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Dish;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/dishes")]
[Authorize]
public class DishesController : ControllerBase
{
    private readonly IDishService _dishService;

    public DishesController(IDishService dishService) => _dishService = dishService;

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var dish = await _dishService.GetByIdAsync(id, ct);
        if (dish is null) return NotFound();
        return Ok(dish);
    }

    [HttpGet("feed")]
    [AllowAnonymous]
    public async Task<IActionResult> GetFeed([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken ct = default)
    {
        var dishes = await _dishService.GetFeedAsync(
            Math.Max(1, page), Math.Clamp(pageSize, 1, 50), ct);
        return Ok(new { items = dishes });
    }

    [HttpPost("{restaurantId:guid}")]
    public async Task<IActionResult> Create(Guid restaurantId, [FromBody] CreateDishRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var dish = await _dishService.CreateAsync(restaurantId, userId, request, ct);
        return CreatedAtAction(nameof(GetById), new { id = dish.Id }, dish);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateDishRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var dish = await _dishService.UpdateAsync(id, userId, request, ct);
        return Ok(dish);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _dishService.DeleteAsync(id, userId, ct);
        return NoContent();
    }
}
