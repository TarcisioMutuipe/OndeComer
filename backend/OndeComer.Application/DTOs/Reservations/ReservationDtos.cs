using System.ComponentModel.DataAnnotations;
using OndeComer.Domain.Enums;

namespace OndeComer.Application.DTOs.Reservations;

public record CreateReservationRequest(
    [Required, MaxLength(100)] string CustomerName,
    [Required, MaxLength(30)] string CustomerPhone,
    [Required] DateTime ReservationDate,
    [Required, MaxLength(10)] string TimeSlot,
    [Range(1, 100)] int PartySize,
    [MaxLength(500)] string? Notes
);

public record UpdateReservationStatusRequest(
    [Required] ReservationStatus Status,
    [MaxLength(500)] string? CancellationReason
);

public record ReservationDto(
    Guid Id,
    Guid RestaurantId,
    string RestaurantName,
    Guid UserId,
    string CustomerName,
    string CustomerPhone,
    DateTime ReservationDate,
    string TimeSlot,
    int PartySize,
    int ToleranceMinutes,
    string? Notes,
    ReservationStatus Status,
    string? CancellationReason,
    DateTime CreatedAt
);

