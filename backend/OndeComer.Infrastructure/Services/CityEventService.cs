using Microsoft.EntityFrameworkCore;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Events;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Services;

public class CityEventService : ICityEventService
{
    private readonly AppDbContext _context;

    public CityEventService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<CityEventDto>> GetActiveEventsAsync(Guid? currentUserId, CancellationToken ct = default)
    {
        var events = await _context.CityEvents
            .AsNoTracking()
            .Include(e => e.Restaurant)
            .Where(e => e.IsActive)
            .OrderByDescending(e => e.CreatedAt)
            .Take(50)
            .ToListAsync(ct);

        Dictionary<Guid, bool> reactionsMap = new();
        if (currentUserId.HasValue && events.Count > 0)
        {
            var eventIds = events.Select(e => e.Id).ToList();
            reactionsMap = await _context.CityEventReactions
                .AsNoTracking()
                .Where(r => r.UserId == currentUserId.Value && eventIds.Contains(r.CityEventId))
                .ToDictionaryAsync(r => r.CityEventId, r => r.IsLike, ct);
        }

        return events.Select(e => new CityEventDto(
            e.Id,
            e.Title,
            e.Description,
            e.ImageUrl,
            e.YouTubeVideoUrl,
            e.LocationOrAddress,
            e.EventDate,
            e.RestaurantId,
            e.Restaurant?.Name,
            e.IsActive,
            e.LikesCount,
            e.DislikesCount,
            reactionsMap.TryGetValue(e.Id, out var userLike) ? userLike : null,
            e.CreatedAt
        ));
    }

    public async Task<CityEventDto?> GetByIdAsync(Guid id, Guid? currentUserId, CancellationToken ct = default)
    {
        var e = await _context.CityEvents
            .AsNoTracking()
            .Include(x => x.Restaurant)
            .FirstOrDefaultAsync(x => x.Id == id, ct);

        if (e is null) return null;

        bool? userReaction = null;
        if (currentUserId.HasValue)
        {
            var reaction = await _context.CityEventReactions
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.CityEventId == id && r.UserId == currentUserId.Value, ct);
            if (reaction is not null)
                userReaction = reaction.IsLike;
        }

        return new CityEventDto(
            e.Id,
            e.Title,
            e.Description,
            e.ImageUrl,
            e.YouTubeVideoUrl,
            e.LocationOrAddress,
            e.EventDate,
            e.RestaurantId,
            e.Restaurant?.Name,
            e.IsActive,
            e.LikesCount,
            e.DislikesCount,
            userReaction,
            e.CreatedAt
        );
    }

    public async Task<CityEventDto> CreateAsync(Guid adminUserId, CreateCityEventRequest request, CancellationToken ct = default)
    {
        var cityEvent = new CityEvent
        {
            Title = request.Title,
            Description = request.Description,
            ImageUrl = request.ImageUrl,
            YouTubeVideoUrl = request.YouTubeVideoUrl,
            LocationOrAddress = request.LocationOrAddress,
            EventDate = request.EventDate.HasValue ? DateTime.SpecifyKind(request.EventDate.Value, DateTimeKind.Utc) : null,
            RestaurantId = request.RestaurantId,
            CreatedByUserId = adminUserId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.CityEvents.Add(cityEvent);
        await _context.SaveChangesAsync(ct);

        string? restaurantName = null;
        if (cityEvent.RestaurantId.HasValue)
        {
            restaurantName = await _context.Restaurants
                .Where(r => r.Id == cityEvent.RestaurantId.Value)
                .Select(r => r.Name)
                .FirstOrDefaultAsync(ct);
        }

        return new CityEventDto(
            cityEvent.Id,
            cityEvent.Title,
            cityEvent.Description,
            cityEvent.ImageUrl,
            cityEvent.YouTubeVideoUrl,
            cityEvent.LocationOrAddress,
            cityEvent.EventDate,
            cityEvent.RestaurantId,
            restaurantName,
            cityEvent.IsActive,
            cityEvent.LikesCount,
            cityEvent.DislikesCount,
            null,
            cityEvent.CreatedAt
        );
    }

    public async Task<CityEventDto> UpdateAsync(Guid id, UpdateCityEventRequest request, CancellationToken ct = default)
    {
        var cityEvent = await _context.CityEvents
            .Include(e => e.Restaurant)
            .FirstOrDefaultAsync(e => e.Id == id, ct)
            ?? throw new NotFoundException("Evento não encontrado.");

        if (request.Title is not null) cityEvent.Title = request.Title;
        if (request.Description is not null) cityEvent.Description = request.Description;
        if (request.ImageUrl is not null) cityEvent.ImageUrl = request.ImageUrl;
        if (request.YouTubeVideoUrl is not null) cityEvent.YouTubeVideoUrl = request.YouTubeVideoUrl;
        if (request.LocationOrAddress is not null) cityEvent.LocationOrAddress = request.LocationOrAddress;
        if (request.EventDate.HasValue) cityEvent.EventDate = DateTime.SpecifyKind(request.EventDate.Value, DateTimeKind.Utc);
        if (request.RestaurantId.HasValue) cityEvent.RestaurantId = request.RestaurantId;
        if (request.IsActive.HasValue) cityEvent.IsActive = request.IsActive.Value;
        cityEvent.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);

        return new CityEventDto(
            cityEvent.Id,
            cityEvent.Title,
            cityEvent.Description,
            cityEvent.ImageUrl,
            cityEvent.YouTubeVideoUrl,
            cityEvent.LocationOrAddress,
            cityEvent.EventDate,
            cityEvent.RestaurantId,
            cityEvent.Restaurant?.Name,
            cityEvent.IsActive,
            cityEvent.LikesCount,
            cityEvent.DislikesCount,
            null,
            cityEvent.CreatedAt
        );
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var cityEvent = await _context.CityEvents.FirstOrDefaultAsync(e => e.Id == id, ct)
            ?? throw new NotFoundException("Evento não encontrado.");

        cityEvent.IsActive = false;
        cityEvent.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(ct);
    }

    public async Task<ReactToEventResultDto> ReactAsync(Guid eventId, Guid userId, bool isLike, CancellationToken ct = default)
    {
        var cityEvent = await _context.CityEvents.FirstOrDefaultAsync(e => e.Id == eventId, ct)
            ?? throw new NotFoundException("Evento não encontrado.");

        var existingReaction = await _context.CityEventReactions
            .FirstOrDefaultAsync(r => r.CityEventId == eventId && r.UserId == userId, ct);

        bool? newReaction = null;

        if (existingReaction is null)
        {
            // First time reacting
            var reaction = new CityEventReaction
            {
                CityEventId = eventId,
                UserId = userId,
                IsLike = isLike,
                CreatedAt = DateTime.UtcNow
            };
            _context.CityEventReactions.Add(reaction);

            if (isLike) cityEvent.LikesCount++;
            else cityEvent.DislikesCount++;

            newReaction = isLike;
        }
        else if (existingReaction.IsLike == isLike)
        {
            // User clicks same button: toggle off (remove reaction)
            _context.CityEventReactions.Remove(existingReaction);

            if (isLike) cityEvent.LikesCount = Math.Max(0, cityEvent.LikesCount - 1);
            else cityEvent.DislikesCount = Math.Max(0, cityEvent.DislikesCount - 1);

            newReaction = null;
        }
        else
        {
            // Switching between like and dislike
            if (isLike)
            {
                cityEvent.DislikesCount = Math.Max(0, cityEvent.DislikesCount - 1);
                cityEvent.LikesCount++;
            }
            else
            {
                cityEvent.LikesCount = Math.Max(0, cityEvent.LikesCount - 1);
                cityEvent.DislikesCount++;
            }

            existingReaction.IsLike = isLike;
            existingReaction.CreatedAt = DateTime.UtcNow;
            newReaction = isLike;
        }

        await _context.SaveChangesAsync(ct);

        return new ReactToEventResultDto(
            cityEvent.Id,
            cityEvent.LikesCount,
            cityEvent.DislikesCount,
            newReaction
        );
    }
}

