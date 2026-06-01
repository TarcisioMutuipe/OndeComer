using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Promotion;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/promotions")]
public class PromotionsController : ControllerBase
{
    private readonly IUnitOfWork _uow;

    public PromotionsController(IUnitOfWork uow) => _uow = uow;

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(page, 1);
        var promotions = await _uow.Promotions.GetActiveAsync(page, pageSize, ct);
        var dtos = promotions.Select(p => ToDto(p));
        return Ok(new { items = dtos, page, pageSize });
    }

    [HttpGet("restaurant/{restaurantId:guid}")]
    public async Task<IActionResult> GetByRestaurant(Guid restaurantId, CancellationToken ct)
    {
        var promotions = await _uow.Promotions.GetByRestaurantAsync(restaurantId, ct);
        return Ok(promotions.Select(p => ToDto(p)));
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePromotionRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var restaurant = await _uow.Restaurants.GetByOwnerIdAsync(userId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado para este usuário.");

        if (request.ExpiresAt.HasValue && request.ExpiresAt.Value <= DateTime.UtcNow)
            throw new AppException("A data de expiração deve ser no futuro.", 400);

        var promotion = new Promotion
        {
            RestaurantId = restaurant.Id,
            Title = request.Title,
            Description = request.Description,
            ImageUrl = request.ImageUrl,
            DiscountPercent = request.DiscountPercent,
            ExpiresAt = request.ExpiresAt,
            IsActive = true
        };

        await _uow.Promotions.AddAsync(promotion, ct);
        await _uow.CommitAsync(ct);

        var dto = ToDto(promotion, restaurant.Name, restaurant.LogoUrl);
        return CreatedAtAction(nameof(GetAll), dto);
    }

    [Authorize]
    [HttpDelete("{promotionId:guid}")]
    public async Task<IActionResult> Delete(Guid promotionId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var restaurant = await _uow.Restaurants.GetByOwnerIdAsync(userId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado para este usuário.");

        var belongs = await _uow.Promotions.BelongsToRestaurantAsync(promotionId, restaurant.Id, ct);
        if (!belongs) throw new NotFoundException("Promoção não encontrada.");

        var promotion = await _uow.Promotions.GetByIdAsync(promotionId, ct);
        promotion!.IsActive = false;
        await _uow.CommitAsync(ct);

        return NoContent();
    }

    [Authorize]
    [HttpPut("{promotionId:guid}")]
    public async Task<IActionResult> Update(Guid promotionId, [FromBody] UpdatePromotionRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var restaurant = await _uow.Restaurants.GetByOwnerIdAsync(userId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado para este usuário.");

        var belongs = await _uow.Promotions.BelongsToRestaurantAsync(promotionId, restaurant.Id, ct);
        if (!belongs) throw new NotFoundException("Promoção não encontrada.");

        var promotion = await _uow.Promotions.GetByIdAsync(promotionId, ct)
            ?? throw new NotFoundException("Promoção não encontrada.");

        if (request.Title != null) promotion.Title = request.Title;
        if (request.Description != null) promotion.Description = request.Description;
        if (request.ImageUrl != null) promotion.ImageUrl = request.ImageUrl;
        if (request.DiscountPercent.HasValue) promotion.DiscountPercent = request.DiscountPercent;
        if (request.ExpiresAt.HasValue) promotion.ExpiresAt = request.ExpiresAt;
        if (request.IsActive.HasValue) promotion.IsActive = request.IsActive.Value;

        await _uow.CommitAsync(ct);
        return Ok(ToDto(promotion, restaurant.Name, restaurant.LogoUrl));
    }

    private static PromotionDto ToDto(Promotion p, string? restaurantName = null, string? logoUrl = null)
        => new(p.Id, p.RestaurantId,
               restaurantName ?? p.Restaurant?.Name ?? string.Empty,
               logoUrl ?? p.Restaurant?.LogoUrl,
               p.Title, p.Description, p.ImageUrl,
               p.DiscountPercent, p.ExpiresAt, p.CreatedAt);
}

