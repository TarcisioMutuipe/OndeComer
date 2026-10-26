using System.Net.Http.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using OndeComer.Application.Interfaces;

namespace OndeComer.Infrastructure.Services;

/// <summary>
/// Firebase Cloud Messaging sender via HTTP v1 API.
/// Requires "Firebase:ServerKey" in configuration.
/// Falls back to logging if no key is configured.
/// </summary>
public class FcmPushSender : IPushSender
{
    private readonly HttpClient _http;
    private readonly string? _serverKey;
    private readonly ILogger<FcmPushSender> _logger;

    public FcmPushSender(IHttpClientFactory httpFactory, IConfiguration config, ILogger<FcmPushSender> logger)
    {
        _http = httpFactory.CreateClient("FCM");
        _serverKey = config["Firebase:ServerKey"];
        _logger = logger;
    }

    public async Task<bool> SendAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
    {
        if (string.IsNullOrEmpty(_serverKey))
        {
            _logger.LogWarning("[FCM] No server key configured. Would send: '{Title}' to token {Token}", title, fcmToken[..8]);
            return false;
        }

        var payload = new
        {
            to = fcmToken,
            notification = new { title, body },
            data
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "https://fcm.googleapis.com/fcm/send")
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.TryAddWithoutValidation("Authorization", $"key={_serverKey}");

        var response = await _http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync(ct);
            _logger.LogError("[FCM] Send failed ({Status}): {Error}", response.StatusCode, err);
            return false;
        }

        return true;
    }

    public async Task<bool> SendMultipleAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null, CancellationToken ct = default)
    {
        var tokens = fcmTokens.ToList();
        if (tokens.Count == 0) return false;

        if (string.IsNullOrEmpty(_serverKey))
        {
            _logger.LogWarning("[FCM] No server key configured. Would send: '{Title}' to {Count} devices", title, tokens.Count);
            return false;
        }

        var payload = new
        {
            registration_ids = tokens,
            notification = new { title, body },
            data
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "https://fcm.googleapis.com/fcm/send")
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.TryAddWithoutValidation("Authorization", $"key={_serverKey}");

        var response = await _http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync(ct);
            _logger.LogError("[FCM] SendMultiple failed ({Status}): {Error}", response.StatusCode, err);
            return false;
        }

        return true;
    }
}
