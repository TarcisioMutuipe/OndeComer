using Microsoft.EntityFrameworkCore;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Reservations;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Services;

public class ReservationService : IReservationService
{
    private readonly AppDbContext _context;

    public ReservationService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ReservationDto> CreateAsync(Guid restaurantId, Guid userId, CreateReservationRequest request, CancellationToken ct = default)
    {
        var restaurant = await _context.Restaurants
            .FirstOrDefaultAsync(r => r.Id == restaurantId && r.IsActive, ct)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        if (!restaurant.AllowsReservations)
            throw new BadRequestException("Este restaurante não está aceitando reservas pelo aplicativo.");

        var resDate = DateTime.SpecifyKind(request.ReservationDate.Date, DateTimeKind.Utc);
        var todayUtc = DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);

        if (resDate < todayUtc)
            throw new BadRequestException("A data da reserva não pode ser no passado.");

        // Check table capacity for this slot
        if (restaurant.TablesAvailableForReservation > 0)
        {
            var bookedCount = await _context.RestaurantReservations
                .CountAsync(r => r.RestaurantId == restaurantId
                    && r.ReservationDate == resDate
                    && r.TimeSlot == request.TimeSlot
                    && r.Status != ReservationStatus.Cancelled
                    && r.Status != ReservationStatus.NoShow, ct);

            if (bookedCount >= restaurant.TablesAvailableForReservation)
            {
                throw new BadRequestException("Não há mesas disponíveis para este horário. Por favor, selecione outro horário.");
            }
        }

        var reservation = new RestaurantReservation
        {
            RestaurantId = restaurantId,
            UserId = userId,
            CustomerName = request.CustomerName.Trim(),
            CustomerPhone = request.CustomerPhone.Trim(),
            ReservationDate = resDate,
            TimeSlot = request.TimeSlot.Trim(),
            PartySize = Math.Max(1, request.PartySize),
            ToleranceMinutes = 15,
            Notes = request.Notes?.Trim(),
            Status = ReservationStatus.Confirmed,
            CreatedAt = DateTime.UtcNow,
            StatusUpdatedAt = DateTime.UtcNow
        };

        _context.RestaurantReservations.Add(reservation);
        await _context.SaveChangesAsync(ct);

        return ToDto(reservation, restaurant.Name);
    }

    public async Task<IEnumerable<ReservationDto>> GetRestaurantReservationsAsync(
        Guid restaurantId, Guid requesterId, DateTime? date = null, ReservationStatus? status = null, CancellationToken ct = default)
    {
        var restaurant = await _context.Restaurants
            .FirstOrDefaultAsync(r => r.Id == restaurantId, ct)
            ?? throw new NotFoundException("Restaurante não encontrado.");

        var requester = await _context.Users.FindAsync(new object[] { requesterId }, ct);
        if (requester?.ProfileType != ProfileType.Admin && restaurant.OwnerUserId != requesterId)
            throw new ForbiddenException("Você não tem permissão para gerenciar reservas deste restaurante.");

        var query = _context.RestaurantReservations
            .AsNoTracking()
            .Where(r => r.RestaurantId == restaurantId);

        if (date.HasValue)
        {
            var filterDate = DateTime.SpecifyKind(date.Value.Date, DateTimeKind.Utc);
            query = query.Where(r => r.ReservationDate == filterDate);
        }

        if (status.HasValue)
        {
            query = query.Where(r => r.Status == status.Value);
        }

        var list = await query
            .OrderBy(r => r.ReservationDate)
            .ThenBy(r => r.TimeSlot)
            .ToListAsync(ct);

        return list.Select(r => ToDto(r, restaurant.Name));
    }

    public async Task<IEnumerable<ReservationDto>> GetUserReservationsAsync(Guid userId, CancellationToken ct = default)
    {
        var list = await _context.RestaurantReservations
            .AsNoTracking()
            .Include(r => r.Restaurant)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.ReservationDate)
            .ThenByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

        return list.Select(r => ToDto(r, r.Restaurant?.Name ?? "Restaurante"));
    }

    public async Task<ReservationDto> UpdateStatusAsync(
        Guid reservationId, Guid requesterId, UpdateReservationStatusRequest request, CancellationToken ct = default)
    {
        var reservation = await _context.RestaurantReservations
            .Include(r => r.Restaurant)
            .FirstOrDefaultAsync(r => r.Id == reservationId, ct)
            ?? throw new NotFoundException("Reserva não encontrada.");

        var requester = await _context.Users.FindAsync(new object[] { requesterId }, ct);
        if (requester?.ProfileType != ProfileType.Admin && reservation.Restaurant.OwnerUserId != requesterId)
            throw new ForbiddenException("Você não tem permissão para atualizar esta reserva.");

        reservation.Status = request.Status;
        if (!string.IsNullOrWhiteSpace(request.CancellationReason))
            reservation.CancellationReason = request.CancellationReason.Trim();

        reservation.StatusUpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(ct);

        return ToDto(reservation, reservation.Restaurant.Name);
    }

    public async Task<ReservationDto> CancelByUserAsync(
        Guid reservationId, Guid userId, string? reason = null, CancellationToken ct = default)
    {
        var reservation = await _context.RestaurantReservations
            .Include(r => r.Restaurant)
            .FirstOrDefaultAsync(r => r.Id == reservationId && r.UserId == userId, ct)
            ?? throw new NotFoundException("Reserva não encontrada.");

        if (reservation.Status == ReservationStatus.Cancelled)
            return ToDto(reservation, reservation.Restaurant.Name);

        reservation.Status = ReservationStatus.Cancelled;
        reservation.CancellationReason = string.IsNullOrWhiteSpace(reason) ? "Cancelada pelo cliente" : reason.Trim();
        reservation.StatusUpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);

        return ToDto(reservation, reservation.Restaurant.Name);
    }

    private static ReservationDto ToDto(RestaurantReservation r, string restaurantName) => new(
        r.Id,
        r.RestaurantId,
        restaurantName,
        r.UserId,
        r.CustomerName,
        r.CustomerPhone,
        r.ReservationDate,
        r.TimeSlot,
        r.PartySize,
        r.ToleranceMinutes,
        r.Notes,
        r.Status,
        r.CancellationReason,
        r.CreatedAt
    );
}

