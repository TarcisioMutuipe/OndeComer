using OndeComer.Application.DTOs.CheckIn;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Application.Common.Exceptions;

namespace OndeComer.Infrastructure.Services;

public class CheckInService : ICheckInService
{
    private readonly ICheckInRepository _checkInRepository;
    private readonly IRestaurantRepository _restaurantRepository;
    private const double MaxDistanceMeters = 200; // 200m radius for check-in
    private const int MaxCheckInsPerDay = 1; // 1 check-in per restaurant per day
    private const int PointsPerCheckIn = 10;

    public CheckInService(ICheckInRepository checkInRepository, IRestaurantRepository restaurantRepository)
    {
        _checkInRepository = checkInRepository;
        _restaurantRepository = restaurantRepository;
    }

    public async Task<CheckInResponse> CheckInAsync(Guid userId, CheckInRequest request)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(request.RestaurantId)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        // Validate distance
        var distance = CalculateHaversineDistance(
            request.Latitude, request.Longitude,
            restaurant.Latitude, restaurant.Longitude);

        var isValidated = distance <= MaxDistanceMeters;

        // Check daily limit
        var todayCount = await _checkInRepository.GetCheckInCountTodayAsync(userId, request.RestaurantId);
        if (todayCount >= MaxCheckInsPerDay)
            throw new BusinessRuleException("Você já fez check-in neste restaurante hoje.");

        var checkIn = new CheckIn
        {
            UserId = userId,
            RestaurantId = request.RestaurantId,
            UserLatitude = request.Latitude,
            UserLongitude = request.Longitude,
            IsValidated = isValidated,
            PointsAwarded = isValidated ? PointsPerCheckIn : 0
        };

        await _checkInRepository.AddAsync(checkIn);

        return new CheckInResponse(
            checkIn.Id,
            restaurant.Id,
            restaurant.Name,
            checkIn.CheckInTime,
            checkIn.PointsAwarded,
            checkIn.IsValidated
        );
    }

    public async Task<CheckInHistoryResponse> GetUserHistoryAsync(Guid userId, int page, int pageSize)
    {
        var checkIns = await _checkInRepository.GetByUserAsync(userId, page, pageSize);
        var totalPoints = await _checkInRepository.GetTotalPointsByUserAsync(userId);

        var items = checkIns.Select(c => new CheckInResponse(
            c.Id, c.RestaurantId, c.Restaurant.Name, c.CheckInTime, c.PointsAwarded, c.IsValidated
        ));

        return new CheckInHistoryResponse(items, totalPoints, page, pageSize);
    }

    public async Task<CheckInHistoryResponse> GetRestaurantCheckInsAsync(Guid restaurantId, int page, int pageSize)
    {
        var checkIns = await _checkInRepository.GetByRestaurantAsync(restaurantId, page, pageSize);

        var items = checkIns.Select(c => new CheckInResponse(
            c.Id, c.RestaurantId, c.Restaurant.Name, c.CheckInTime, c.PointsAwarded, c.IsValidated
        ));

        return new CheckInHistoryResponse(items, 0, page, pageSize);
    }

    public async Task<QrCodeResponse> GenerateQrDataAsync(Guid restaurantId)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        var deepLink = $"ondecomer://checkin/{restaurantId}";
        var qrContent = deepLink;

        return new QrCodeResponse(restaurant.Id, restaurant.Name, qrContent, deepLink);
    }

    public async Task<int> GetUserPointsAsync(Guid userId)
    {
        return await _checkInRepository.GetTotalPointsByUserAsync(userId);
    }

    /// <summary>
    /// Haversine formula to calculate distance between two coordinates in meters.
    /// </summary>
    private static double CalculateHaversineDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371000; // Earth radius in meters
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180;
}
