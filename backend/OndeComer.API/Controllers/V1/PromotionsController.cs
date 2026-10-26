using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Promotion;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/promotions")]
public class PromotionsController : ControllerBase
{
    private readonly IPromotionService _promotionService;

    public PromotionsController(IPromotionService promotionService)
    {
        _promotionService = promotionService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _promotionService.GetFeedAsync(page, pageSize, ct);
        return Ok(result);
    }

    [HttpGet("restaurant/{restaurantId:guid}")]
    public async Task<IActionResult> GetByRestaurant(Guid restaurantId, CancellationToken ct)
    {
        var promotions = await _promotionService.GetByRestaurantAsync(restaurantId, ct);
        return Ok(promotions);
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePromotionRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var dto = await _promotionService.CreateAsync(userId, request, ct);
        return CreatedAtAction(nameof(GetAll), dto);
    }

    [Authorize]
    [HttpDelete("{promotionId:guid}")]
    public async Task<IActionResult> Delete(Guid promotionId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _promotionService.DeleteAsync(userId, promotionId, ct);
        return NoContent();
    }

    [Authorize]
    [HttpPut("{promotionId:guid}")]
    public async Task<IActionResult> Update(Guid promotionId, [FromBody] UpdatePromotionRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var dto = await _promotionService.UpdateAsync(userId, promotionId, request, ct);
        return Ok(dto);
    }

    [Authorize]
    [HttpPost("{promotionId:guid}/claim")]
    public async Task<IActionResult> Claim(Guid promotionId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _promotionService.ClaimAsync(userId, promotionId, ct);
        return Ok(result);
    }

    [Authorize]
    [HttpGet("me/tickets")]
    public async Task<IActionResult> GetMyTickets(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _promotionService.GetMyTicketsAsync(userId, ct);
        return Ok(result);
    }

    [Authorize]
    [HttpGet("restaurant/tickets")]
    public async Task<IActionResult> GetRestaurantTickets(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _promotionService.GetRestaurantTicketsAsync(userId, ct);
        return Ok(result);
    }

    [Authorize]
    [HttpPost("finalize")]
    public async Task<IActionResult> Finalize([FromBody] FinalizePromotionTicketRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _promotionService.FinalizeAsync(userId, request, ct);
        return Ok(result);
    }
}
