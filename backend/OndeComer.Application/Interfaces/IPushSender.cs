using OndeComer.Application.DTOs.Notification;

namespace OndeComer.Application.Interfaces;

public interface IPushSender
{
    Task SendAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default);
    Task SendMultipleAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default);
}
