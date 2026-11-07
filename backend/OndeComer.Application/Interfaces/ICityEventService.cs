using OndeComer.Application.DTOs.Events;

namespace OndeComer.Application.Interfaces;

public interface ICityEventService
{
    Task<IEnumerable<CityEventDto>> GetActiveEventsAsync(Guid? currentUserId, CancellationToken ct = default);
    Task<CityEventDto?> GetByIdAsync(Guid id, Guid? currentUserId, CancellationToken ct = default);
    Task<CityEventDto> CreateAsync(Guid adminUserId, CreateCityEventRequest request, CancellationToken ct = default);
    Task<CityEventDto> UpdateAsync(Guid id, UpdateCityEventRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
    Task<ReactToEventResultDto> ReactAsync(Guid eventId, Guid userId, bool isLike, CancellationToken ct = default);
}

