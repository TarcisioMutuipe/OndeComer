using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using OndeComer.Application.DTOs.Notification;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly AppDbContext _db;
    private readonly IPushSender _pushSender;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(AppDbContext db, IPushSender pushSender, ILogger<NotificationService> logger)
    {
        _db = db;
        _pushSender = pushSender;
        _logger = logger;
    }

    public async Task RegisterDeviceAsync(Guid userId, RegisterDeviceRequest request, CancellationToken ct = default)
    {
        var existing = await _db.NotificationDevices
            .FirstOrDefaultAsync(d => d.FcmToken == request.FcmToken, ct);

        if (existing != null)
        {
            existing.UserId = userId;
            existing.Platform = request.Platform;
            existing.ApnsToken = request.ApnsToken;
            existing.IsActive = true;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            _db.NotificationDevices.Add(new NotificationDevice
            {
                UserId = userId,
                Platform = request.Platform,
                FcmToken = request.FcmToken,
                ApnsToken = request.ApnsToken,
            });
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task UnregisterDeviceAsync(Guid userId, string fcmToken, CancellationToken ct = default)
    {
        var device = await _db.NotificationDevices
            .FirstOrDefaultAsync(d => d.UserId == userId && d.FcmToken == fcmToken, ct);

        if (device != null)
        {
            device.IsActive = false;
            device.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task<NotificationPreferenceDto> GetPreferencesAsync(Guid userId, CancellationToken ct = default)
    {
        var prefs = await _db.NotificationPreferences
            .FirstOrDefaultAsync(p => p.UserId == userId, ct);

        if (prefs == null)
        {
            return new NotificationPreferenceDto(true, true, true, true);
        }

        return new NotificationPreferenceDto(
            prefs.NewComment,
            prefs.NewReview,
            prefs.PromotionActive,
            prefs.NewDish
        );
    }

    public async Task UpdatePreferencesAsync(Guid userId, UpdatePreferencesRequest request, CancellationToken ct = default)
    {
        var prefs = await _db.NotificationPreferences
            .FirstOrDefaultAsync(p => p.UserId == userId, ct);

        if (prefs == null)
        {
            prefs = new NotificationPreference { UserId = userId };
            _db.NotificationPreferences.Add(prefs);
        }

        prefs.NewComment = request.NewComment;
        prefs.NewReview = request.NewReview;
        prefs.PromotionActive = request.PromotionActive;
        prefs.NewDish = request.NewDish;
        prefs.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
    }

    public async Task<bool> SendPushToUserAsync(Guid userId, PushNotificationDto notification, CancellationToken ct = default)
    {
        var tokens = await _db.NotificationDevices
            .Where(d => d.UserId == userId && d.IsActive)
            .Select(d => d.FcmToken)
            .ToListAsync(ct);

        if (tokens.Count == 0) return false;

        var data = notification.Data ?? new Dictionary<string, string>();
        if (notification.DeepLink != null)
            data["deepLink"] = notification.DeepLink;

        try
        {
            return await _pushSender.SendMultipleAsync(tokens, notification.Title, notification.Body, data, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send push to user {UserId}", userId);
            return false;
        }
    }

    public async Task<bool> SendPushToRestaurantOwnerAsync(Guid restaurantId, PushNotificationDto notification, CancellationToken ct = default)
    {
        var restaurant = await _db.Restaurants.FindAsync(new object[] { restaurantId }, ct);
        if (restaurant == null) return false;

        return await SendPushToUserAsync(restaurant.OwnerUserId, notification, ct);
    }

    public async Task<bool> SendPushToPromotionSubscribersAsync(PushNotificationDto notification, CancellationToken ct = default)
    {
        var userIds = await _db.NotificationDevices
            .Where(d => d.IsActive)
            .Select(d => d.UserId)
            .Distinct()
            .ToListAsync(ct);

        if (userIds.Count == 0)
            return false;

        var preferences = await _db.NotificationPreferences
            .Where(p => userIds.Contains(p.UserId))
            .Select(p => new { p.UserId, p.PromotionActive })
            .ToListAsync(ct);

        var preferenceMap = preferences.ToDictionary(p => p.UserId, p => p.PromotionActive);
        var userIdsToNotify = userIds
            .Where(userId => !preferenceMap.TryGetValue(userId, out var promotionActive) || promotionActive)
            .ToList();

        var anySent = false;

        foreach (var userId in userIdsToNotify)
        {
            anySent |= await SendPushToUserAsync(userId, notification, ct);
        }

        return anySent;
    }
}
