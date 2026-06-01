using System.Collections.Concurrent;
using System.Net;

namespace OndeComer.API.Middleware;

public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RateLimitingMiddleware> _logger;
    private static readonly ConcurrentDictionary<string, ClientRateInfo> _clients = new();
    private const int MaxRequestsPerMinute = 60;
    private const int BruteForceMaxAttempts = 10;
    private const int BruteForceLockoutMinutes = 15;

    public RateLimitingMiddleware(RequestDelegate next, ILogger<RateLimitingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientIp = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var path = context.Request.Path.Value?.ToLowerInvariant() ?? "";
        var key = $"{clientIp}:{path}";

        // Brute force protection for auth endpoints
        if (path.Contains("/auth/login") || path.Contains("/auth/register"))
        {
            var bruteKey = $"brute:{clientIp}";
            var bruteInfo = _clients.GetOrAdd(bruteKey, _ => new ClientRateInfo());

            lock (bruteInfo)
            {
                if (bruteInfo.IsLockedOut && bruteInfo.LockoutUntil > DateTime.UtcNow)
                {
                    _logger.LogWarning("Brute force lockout for IP {IP}", clientIp);
                    context.Response.StatusCode = (int)HttpStatusCode.TooManyRequests;
                    context.Response.Headers["Retry-After"] = BruteForceLockoutMinutes.ToString();
                    return;
                }

                if (bruteInfo.IsLockedOut && bruteInfo.LockoutUntil <= DateTime.UtcNow)
                {
                    bruteInfo.Reset();
                }
            }
        }

        // General rate limiting
        var rateInfo = _clients.GetOrAdd(clientIp, _ => new ClientRateInfo());

        lock (rateInfo)
        {
            rateInfo.CleanupOldRequests();

            if (rateInfo.RequestCount >= MaxRequestsPerMinute)
            {
                _logger.LogWarning("Rate limit exceeded for IP {IP}", clientIp);
                context.Response.StatusCode = (int)HttpStatusCode.TooManyRequests;
                context.Response.Headers["Retry-After"] = "60";
                return;
            }

            rateInfo.AddRequest();
        }

        await _next(context);

        // Track failed auth attempts for brute force
        if ((path.Contains("/auth/login") || path.Contains("/auth/register"))
            && context.Response.StatusCode == 401)
        {
            var bruteKey = $"brute:{clientIp}";
            var bruteInfo = _clients.GetOrAdd(bruteKey, _ => new ClientRateInfo());

            lock (bruteInfo)
            {
                bruteInfo.FailedAttempts++;
                if (bruteInfo.FailedAttempts >= BruteForceMaxAttempts)
                {
                    bruteInfo.IsLockedOut = true;
                    bruteInfo.LockoutUntil = DateTime.UtcNow.AddMinutes(BruteForceLockoutMinutes);
                    _logger.LogWarning("IP {IP} locked out for brute force after {Attempts} attempts", clientIp, bruteInfo.FailedAttempts);
                }
            }
        }
    }

    private class ClientRateInfo
    {
        private readonly Queue<DateTime> _requests = new();
        public int FailedAttempts { get; set; }
        public bool IsLockedOut { get; set; }
        public DateTime? LockoutUntil { get; set; }

        public int RequestCount => _requests.Count;

        public void AddRequest() => _requests.Enqueue(DateTime.UtcNow);

        public void CleanupOldRequests()
        {
            var oneMinuteAgo = DateTime.UtcNow.AddMinutes(-1);
            while (_requests.Count > 0 && _requests.Peek() < oneMinuteAgo)
                _requests.Dequeue();
        }

        public void Reset()
        {
            FailedAttempts = 0;
            IsLockedOut = false;
            LockoutUntil = null;
        }
    }
}
