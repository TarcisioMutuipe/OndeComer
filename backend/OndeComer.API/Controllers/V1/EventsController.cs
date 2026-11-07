using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Events;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/events")]
public class EventsController : ControllerBase
{
    private readonly ICityEventService _eventService;

    public EventsController(ICityEventService eventService)
    {
        _eventService = eventService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        Guid? currentUserId = null;
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (Guid.TryParse(sub, out var parsed)) currentUserId = parsed;

        var events = await _eventService.GetActiveEventsAsync(currentUserId, ct);
        return Ok(events);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        Guid? currentUserId = null;
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (Guid.TryParse(sub, out var parsed)) currentUserId = parsed;

        var e = await _eventService.GetByIdAsync(id, currentUserId, ct);
        if (e is null) return NotFound();
        return Ok(e);
    }

    [Authorize]
    [HttpPost("{id:guid}/react")]
    public async Task<IActionResult> React(Guid id, [FromBody] ReactToEventRequest request, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _eventService.ReactAsync(id, userId, request.IsLike, ct);
        return Ok(result);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateCityEventRequest request, CancellationToken ct)
    {
        var adminId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var created = await _eventService.CreateAsync(adminId, request, ct);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCityEventRequest request, CancellationToken ct)
    {
        var updated = await _eventService.UpdateAsync(id, request, ct);
        return Ok(updated);
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await _eventService.DeleteAsync(id, ct);
        return NoContent();
    }
}

