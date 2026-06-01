using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Moderation;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/moderation")]
[Authorize]
public class ModerationController : ControllerBase
{
    private readonly IModerationService _moderationService;

    public ModerationController(IModerationService moderationService)
    {
        _moderationService = moderationService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    /// <summary>
    /// Escaneia texto para conteúdo ofensivo.
    /// </summary>
    [HttpPost("scan-text")]
    public async Task<ActionResult<ModerationResult>> ScanText([FromBody] ScanTextRequest request)
    {
        var result = await _moderationService.ScanTextAsync(request);
        return Ok(result);
    }

    /// <summary>
    /// Escaneia imagem para conteúdo inadequado.
    /// </summary>
    [HttpPost("scan-image")]
    public async Task<ActionResult<ModerationResult>> ScanImage([FromBody] ScanImageRequest request)
    {
        var result = await _moderationService.ScanImageAsync(request);
        return Ok(result);
    }

    /// <summary>
    /// Lista logs de moderação (admin).
    /// </summary>
    [HttpGet("logs")]
    public async Task<ActionResult<IEnumerable<ModerationLogDto>>> GetLogs(
        [FromQuery] string? result,
        [FromQuery] string? entityType,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var logs = await _moderationService.GetLogsAsync(result, entityType, page, pageSize);
        return Ok(logs);
    }

    /// <summary>
    /// Revisão humana de um log sinalizado.
    /// </summary>
    [HttpPost("logs/{logId:guid}/review")]
    public async Task<ActionResult<ModerationLogDto>> ReviewLog(Guid logId, [FromBody] ReviewModerationRequest request)
    {
        var userId = GetCurrentUserId();
        var log = await _moderationService.ReviewLogAsync(logId, userId, request.Decision);
        return Ok(log);
    }
}
