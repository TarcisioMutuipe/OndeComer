using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1")]
public class LocalesController : ControllerBase
{
    [HttpGet("locales")]
    [AllowAnonymous]
    public ActionResult<IEnumerable<object>> GetLocales()
    {
        var locales = new[]
        {
            new { code = "pt-BR", name = "Português (Brasil)", isDefault = true },
            new { code = "en-US", name = "English (US)", isDefault = false }
        };
        return Ok(locales);
    }
}

[ApiController]
[Route("api/v1/account")]
[Authorize]
public class AccountController : ControllerBase
{
    private readonly IAdminService _adminService;

    public AccountController(IAdminService adminService)
    {
        _adminService = adminService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    /// <summary>
    /// Solicita exclusão da própria conta (LGPD - direito ao esquecimento).
    /// </summary>
    [HttpDelete("me")]
    public async Task<IActionResult> DeleteMyAccount()
    {
        var userId = GetCurrentUserId();
        await _adminService.DeleteUserAsync(userId);
        return NoContent();
    }

    /// <summary>
    /// Exporta dados pessoais (LGPD - direito à portabilidade).
    /// </summary>
    [HttpGet("me/export")]
    public async Task<IActionResult> ExportMyData([FromQuery] string format = "json")
    {
        var userId = GetCurrentUserId();
        var data = await _adminService.ExportUserDataAsync(userId, format);
        var contentType = format.Equals("csv", StringComparison.OrdinalIgnoreCase) ? "text/csv" : "application/json";
        var ext = format.Equals("csv", StringComparison.OrdinalIgnoreCase) ? "csv" : "json";
        return File(data, contentType, $"meus_dados.{ext}");
    }
}
