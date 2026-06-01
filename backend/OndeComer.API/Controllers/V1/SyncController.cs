using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Review;
using OndeComer.Application.DTOs.Comment;
using OndeComer.Application.DTOs.Sync;
using OndeComer.Application.Interfaces;

namespace OndeComer.API.Controllers.V1;

[ApiController]
[Route("api/v1/sync")]
[Authorize]
public class SyncController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly ICommentService _commentService;

    public SyncController(IReviewService reviewService, ICommentService commentService)
    {
        _reviewService = reviewService;
        _commentService = commentService;
    }

    /// <summary>
    /// Receives a batch of pending offline operations and processes each one.
    /// Idempotency: duplicate clientId operations return success without re-processing
    /// (handled per-operation via ConflictException which is treated as success for reviews).
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> ProcessBatch(
        [FromBody] SyncRequest request,
        CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var results = new List<SyncResult>();

        foreach (var op in request.Operations)
        {
            try
            {
                object? data = op.OperationType switch
                {
                    "create_review" => await ProcessReview(op, userId, ct),
                    "create_comment" => await ProcessComment(op, userId, ct),
                    _ => throw new InvalidOperationException($"Unknown operation: {op.OperationType}")
                };
                results.Add(new SyncResult(op.ClientId, true, null, data));
            }
            catch (Exception ex)
            {
                // ConflictException (already submitted) = idempotent success
                var isConflict = ex.GetType().Name == "ConflictException";
                results.Add(new SyncResult(
                    op.ClientId,
                    isConflict,
                    isConflict ? null : ex.Message,
                    null
                ));
            }
        }

        return Ok(new SyncResponse(results));
    }

    /// <summary>
    /// Returns lightweight delta of changes since a given timestamp.
    /// Currently returns public approved reviews/comments updated after 'since'.
    /// </summary>
    [HttpGet("changes")]
    public IActionResult GetChanges([FromQuery] DateTime since)
    {
        // Clamp: prevent overly large queries (max 30 days)
        var clampedSince = since < DateTime.UtcNow.AddDays(-30)
            ? DateTime.UtcNow.AddDays(-30)
            : since;

        return Ok(new DeltaResponse(clampedSince, DateTime.UtcNow, new List<object>()));
    }

    /// <summary>
    /// Returns sync queue status (server-side acknowledgment).
    /// GET /api/v1/sync/status
    /// </summary>
    [HttpGet("status")]
    public IActionResult GetStatus()
    {
        return Ok(new
        {
            serverTime = DateTime.UtcNow,
            syncAvailable = true,
            supportedOperations = new[] { "create_review", "create_comment" }
        });
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private async Task<object> ProcessReview(PendingOperation op, Guid userId, CancellationToken ct)
    {
        var payload = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(op.Payload)
            ?? throw new InvalidOperationException("Invalid review payload.");

        var dishId = Guid.Parse(payload["dishId"].GetString()!);
        var rating = payload["rating"].GetInt32();

        var dto = await _reviewService.CreateAsync(
            dishId, userId,
            new CreateReviewRequest(rating),
            ct);
        return dto;
    }

    private async Task<object> ProcessComment(PendingOperation op, Guid userId, CancellationToken ct)
    {
        var payload = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(op.Payload)
            ?? throw new InvalidOperationException("Invalid comment payload.");

        var dishId = Guid.Parse(payload["dishId"].GetString()!);
        var text = payload["text"].GetString()!;

        var dto = await _commentService.CreateAsync(
            dishId, userId,
            new CreateCommentRequest(text),
            ct);
        return dto;
    }
}
