using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Wishlists;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/wishlists")]
public class WishlistsController : ControllerBase
{
    private readonly IWishlistService _service;
    public WishlistsController(IWishlistService service) => _service = service;

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    /// <summary>Lista públicas acessíveis via token — sem autenticação.</summary>
    [HttpGet("public/{shareToken}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPublic(string shareToken, CancellationToken ct)
    {
        var wishlist = await _service.GetPublicByTokenAsync(shareToken, ct);
        if (wishlist is null) return NotFound();
        return Ok(wishlist);
    }

    /// <summary>Lista todas as wishlists do usuário autenticado.</summary>
    [HttpGet]
    [Authorize]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var list = await _service.GetByUserAsync(userId, ct);
        return Ok(list);
    }

    /// <summary>Retorna uma wishlist por ID (privada = apenas dono).</summary>
    [HttpGet("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var wishlist = await _service.GetByIdAsync(id, userId, ct);
        if (wishlist is null) return NotFound();
        return Ok(wishlist);
    }

    /// <summary>Cria uma nova wishlist.</summary>
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CreateWishlistRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var wishlist = await _service.CreateAsync(userId, request, ct);
        return CreatedAtAction(nameof(GetById), new { id = wishlist.Id }, wishlist);
    }

    /// <summary>Atualiza nome, descrição ou visibilidade da lista.</summary>
    [HttpPut("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateWishlistRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var wishlist = await _service.UpdateAsync(id, userId, request, ct);
        return Ok(wishlist);
    }

    /// <summary>Exclui a wishlist.</summary>
    [HttpDelete("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _service.DeleteAsync(id, userId, ct);
        return NoContent();
    }

    /// <summary>Gera (ou retorna) token de compartilhamento e torna a lista pública.</summary>
    [HttpPost("{id:guid}/share")]
    [Authorize]
    public async Task<IActionResult> Share(Guid id, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var token = await _service.GenerateShareTokenAsync(id, userId, ct);
        return Ok(new { shareToken = token, shareUrl = $"/wishlists/public/{token}" });
    }

    /// <summary>Adiciona um restaurante ou prato à wishlist.</summary>
    [HttpPost("{id:guid}/items")]
    [Authorize]
    public async Task<IActionResult> AddItem(Guid id, [FromBody] AddWishlistItemRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var item = await _service.AddItemAsync(id, userId, request, ct);
        return Created(string.Empty, item);
    }

    /// <summary>Remove um item da wishlist.</summary>
    [HttpDelete("items/{itemId:guid}")]
    [Authorize]
    public async Task<IActionResult> RemoveItem(Guid itemId, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _service.RemoveItemAsync(itemId, userId, ct);
        return NoContent();
    }
}
