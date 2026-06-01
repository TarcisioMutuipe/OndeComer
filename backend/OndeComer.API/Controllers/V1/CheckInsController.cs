using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.CheckIn;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/checkins")]
[Authorize]
public class CheckInsController : ControllerBase
{
    private readonly ICheckInService _checkInService;

    public CheckInsController(ICheckInService checkInService)
    {
        _checkInService = checkInService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    /// <summary>
    /// Realiza check-in em um restaurante (valida distância via Haversine).
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<CheckInResponse>> CheckIn([FromBody] CheckInRequest request)
    {
        var userId = GetCurrentUserId();
        var result = await _checkInService.CheckInAsync(userId, request);
        return Ok(result);
    }

    /// <summary>
    /// Histórico de check-ins do usuário autenticado.
    /// </summary>
    [HttpGet("history")]
    public async Task<ActionResult<CheckInHistoryResponse>> GetMyHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = GetCurrentUserId();
        var result = await _checkInService.GetUserHistoryAsync(userId, page, pageSize);
        return Ok(result);
    }

    /// <summary>
    /// Pontos totais do usuário autenticado.
    /// </summary>
    [HttpGet("points")]
    public async Task<ActionResult<object>> GetMyPoints()
    {
        var userId = GetCurrentUserId();
        var points = await _checkInService.GetUserPointsAsync(userId);
        return Ok(new { totalPoints = points });
    }

    /// <summary>
    /// Check-ins recebidos por um restaurante (owner only).
    /// </summary>
    [HttpGet("restaurant/{restaurantId:guid}")]
    public async Task<ActionResult<CheckInHistoryResponse>> GetRestaurantCheckIns(Guid restaurantId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _checkInService.GetRestaurantCheckInsAsync(restaurantId, page, pageSize);
        return Ok(result);
    }

    /// <summary>
    /// Gera dados para QR Code de um restaurante.
    /// </summary>
    [HttpGet("qr/{restaurantId:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<QrCodeResponse>> GetQrCode(Guid restaurantId)
    {
        var result = await _checkInService.GenerateQrDataAsync(restaurantId);
        return Ok(result);
    }
}
