using OndeComer.Application.DTOs.CheckIn;

namespace OndeComer.Application.Interfaces;

public interface ICheckInService
{
    Task<CheckInResponse> CheckInAsync(Guid userId, CheckInRequest request);
    Task<CheckInHistoryResponse> GetUserHistoryAsync(Guid userId, int page, int pageSize);
    Task<CheckInHistoryResponse> GetRestaurantCheckInsAsync(Guid restaurantId, int page, int pageSize);
    Task<QrCodeResponse> GenerateQrDataAsync(Guid restaurantId);
    Task<int> GetUserPointsAsync(Guid userId);
}
