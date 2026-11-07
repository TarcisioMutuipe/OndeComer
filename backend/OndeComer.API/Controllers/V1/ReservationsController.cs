using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Reservations;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Enums;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Authorize]
public class ReservationsController : ControllerBase
{
    private readonly IReservationService _reservationService;

    public ReservationsController(IReservationService reservationService)
    {
        _reservationService = reservationService;
    }

    [HttpPost("api/v1/restaurants/{restaurantId:guid}/reservations")]
    public async Task<IActionResult> CreateReservation(
        Guid restaurantId, [FromBody] CreateReservationRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var created = await _reservationService.CreateAsync(restaurantId, userId, request, ct);
        return Ok(created);
    }

    [HttpGet("api/v1/restaurants/{restaurantId:guid}/reservations")]
    public async Task<IActionResult> GetRestaurantReservations(
        Guid restaurantId,
        [FromQuery] DateTime? date,
        [FromQuery] ReservationStatus? status,
        CancellationToken ct)
    {
        var requesterId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var list = await _reservationService.GetRestaurantReservationsAsync(restaurantId, requesterId, date, status, ct);
        return Ok(list);
    }

    [HttpGet("api/v1/reservations/my")]
    public async Task<IActionResult> GetMyReservations(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var list = await _reservationService.GetUserReservationsAsync(userId, ct);
        return Ok(list);
    }

    [HttpPut("api/v1/reservations/{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(
        Guid id, [FromBody] UpdateReservationStatusRequest request, CancellationToken ct)
    {
        var requesterId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var updated = await _reservationService.UpdateStatusAsync(id, requesterId, request, ct);
        return Ok(updated);
    }

    [HttpPut("api/v1/reservations/{id:guid}/cancel")]
    public async Task<IActionResult> CancelReservation(
        Guid id, [FromQuery] string? reason, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var updated = await _reservationService.CancelByUserAsync(id, userId, reason, ct);
        return Ok(updated);
    }
}

