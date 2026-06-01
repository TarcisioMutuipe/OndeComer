using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Auth;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? User.FindFirstValue("sub")
        ?? throw new UnauthorizedAccessException());

    /// <summary>Retorna o perfil do usuário autenticado.</summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMe(CancellationToken ct)
    {
        var user = await _userService.GetCurrentUserAsync(CurrentUserId, ct);
        return Ok(user);
    }

    /// <summary>Atualiza o perfil do usuário autenticado.</summary>
    [HttpPut("me")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateMe([FromBody] UpdateProfileRequest request, CancellationToken ct)
    {
        var user = await _userService.UpdateProfileAsync(CurrentUserId, request, ct);
        return Ok(user);
    }

    /// <summary>Verifica se um e-mail está disponível.</summary>
    [HttpGet("check-email")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public async Task<IActionResult> CheckEmail([FromQuery] string email, CancellationToken ct)
    {
        var available = await _userService.CheckEmailAvailableAsync(email, ct);
        return Ok(new { available });
    }

    /// <summary>Verifica se um username está disponível.</summary>
    [HttpGet("check-username")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public async Task<IActionResult> CheckUsername([FromQuery] string username, CancellationToken ct)
    {
        var available = await _userService.CheckUsernameAvailableAsync(username, ct);
        return Ok(new { available });
    }

    /// <summary>Dados públicos de outro usuário.</summary>
    [HttpGet("{id:guid}/public")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPublicProfile(Guid id, CancellationToken ct)
    {
        var user = await _userService.GetCurrentUserAsync(id, ct);
        return Ok(new
        {
            user.Id,
            user.Name,
            user.Username,
            user.ProfileType,
            user.CreatedAt
        });
    }
}
