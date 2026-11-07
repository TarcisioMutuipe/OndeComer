using OndeComer.Application.DTOs.Reservations;
using OndeComer.Domain.Enums;

namespace OndeComer.Application.Interfaces;

public interface IReservationService
{
    Task<ReservationDto> CreateAsync(Guid restaurantId, Guid userId, CreateReservationRequest request, CancellationToken ct = default);
    Task<IEnumerable<ReservationDto>> GetRestaurantReservationsAsync(Guid restaurantId, Guid requesterId, DateTime? date = null, ReservationStatus? status = null, CancellationToken ct = default);
    Task<IEnumerable<ReservationDto>> GetUserReservationsAsync(Guid userId, CancellationToken ct = default);
    Task<ReservationDto> UpdateStatusAsync(Guid reservationId, Guid requesterId, UpdateReservationStatusRequest request, CancellationToken ct = default);
    Task<ReservationDto> CancelByUserAsync(Guid reservationId, Guid userId, string? reason = null, CancellationToken ct = default);
}

