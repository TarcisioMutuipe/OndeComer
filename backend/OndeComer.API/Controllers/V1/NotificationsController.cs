using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Notification;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    private Guid GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(sub);
    }

    [HttpPost("register-device")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _notificationService.RegisterDeviceAsync(userId, request, ct);
        return Ok(new { message = "Dispositivo registrado com sucesso." });
    }

    [HttpPost("unregister-device")]
    public async Task<IActionResult> UnregisterDevice([FromBody] UnregisterDeviceRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _notificationService.UnregisterDeviceAsync(userId, request.FcmToken, ct);
        return Ok(new { message = "Dispositivo removido." });
    }

    [HttpGet("preferences")]
    public async Task<IActionResult> GetPreferences(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var prefs = await _notificationService.GetPreferencesAsync(userId, ct);
        return Ok(prefs);
    }

    [HttpPut("preferences")]
    public async Task<IActionResult> UpdatePreferences([FromBody] UpdatePreferencesRequest request, CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _notificationService.UpdatePreferencesAsync(userId, request, ct);
        return Ok(new { message = "Preferências atualizadas." });
    }

    /// <summary>Envio de push de teste para o próprio dispositivo.</summary>
    [HttpPost("test")]
    public async Task<IActionResult> TestPush(CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        await _notificationService.SendPushToUserAsync(userId, new PushNotificationDto(
            "Teste de Notificação",
            "Se você recebeu esta mensagem, as notificações estão funcionando!",
            null,
            new Dictionary<string, string> { ["type"] = "test" }
        ), ct);
        return Ok(new { message = "Notificação de teste enviada." });
    }
}

public record UnregisterDeviceRequest(string FcmToken);
