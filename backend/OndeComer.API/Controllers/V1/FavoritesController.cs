using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Favorites;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/favorites")]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IFavoriteService _service;
    public FavoritesController(IFavoriteService service) => _service = service;

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    /// <summary>Lista todos os favoritos do usuário autenticado.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var list = await _service.GetByUserAsync(userId, ct);
        return Ok(list);
    }

    /// <summary>Verifica se um restaurante ou prato está favoritado.</summary>
    [HttpGet("check")]
    public async Task<IActionResult> Check(
        [FromQuery] Guid? restaurantId,
        [FromQuery] Guid? dishId,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var isFav = await _service.IsFavoritedAsync(userId, restaurantId, dishId, ct);
        return Ok(new { isFavorited = isFav });
    }

    /// <summary>Alterna (adiciona/remove) um favorito.</summary>
    [HttpPost("toggle")]
    public async Task<IActionResult> Toggle([FromBody] ToggleFavoriteRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var (added, favorite) = await _service.ToggleAsync(userId, request, ct);
        return Ok(new { added, favorite });
    }
}
