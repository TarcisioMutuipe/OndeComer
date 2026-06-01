using OndeComer.Application.DTOs.Notification;

namespace OndeComer.Application.Interfaces;

public interface INotificationService
{
    Task RegisterDeviceAsync(Guid userId, RegisterDeviceRequest request, CancellationToken ct = default);
    Task UnregisterDeviceAsync(Guid userId, string fcmToken, CancellationToken ct = default);
    Task<NotificationPreferenceDto> GetPreferencesAsync(Guid userId, CancellationToken ct = default);
    Task UpdatePreferencesAsync(Guid userId, UpdatePreferencesRequest request, CancellationToken ct = default);
    Task SendPushToUserAsync(Guid userId, PushNotificationDto notification, CancellationToken ct = default);
    Task SendPushToRestaurantOwnerAsync(Guid restaurantId, PushNotificationDto notification, CancellationToken ct = default);
}
