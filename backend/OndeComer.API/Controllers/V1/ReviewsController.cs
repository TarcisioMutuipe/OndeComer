using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OndeComer.Application.DTOs.Comment;
using OndeComer.Application.DTOs.Review;
using OndeComer.Application.Interfaces;
using System.Security.Claims;

namespace OndeComer.API.Controllers.V1;

/// <summary>
/// POST   /api/v1/dishes/{dishId}/review    — submit a star rating
/// POST   /api/v1/dishes/{dishId}/comment   — submit a text comment
/// GET    /api/v1/dishes/{dishId}/comments  — approved comments (public)
/// GET    /api/v1/comments/pending          — pending for restaurant owner
/// PUT    /api/v1/comments/{id}/moderate    — approve / reject
/// GET    /api/v1/reviews/pending           — pending ratings for restaurant owner
/// PUT    /api/v1/reviews/{id}/moderate     — approve / reject rating
/// </summary>
[ApiController]
[Route("api/v1")]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly ICommentService _commentService;
    private readonly IRestaurantService _restaurantService;

    public ReviewsController(IReviewService reviewService, ICommentService commentService, IRestaurantService restaurantService)
    {
        _reviewService = reviewService;
        _commentService = commentService;
        _restaurantService = restaurantService;
    }

    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Reviews (ratings) ─────────────────────────────────────────────────

    [HttpPost("dishes/{dishId:guid}/review")]
    [Authorize]
    public async Task<IActionResult> CreateReview(Guid dishId, [FromBody] CreateReviewRequest request, CancellationToken ct)
    {
        var dto = await _reviewService.CreateAsync(dishId, CurrentUserId, request, ct);
        return StatusCode(201, dto);
    }

    [HttpGet("reviews/pending")]
    [Authorize]
    public async Task<IActionResult> GetPendingReviews(CancellationToken ct)
    {
        var restaurant = await _restaurantService.GetByOwnerIdAsync(CurrentUserId, ct);
        if (restaurant == null) return Ok(Array.Empty<object>());
        var reviews = await _reviewService.GetPendingByRestaurantAsync(restaurant.Id, ct);
        return Ok(reviews);
    }

    [HttpPut("reviews/{reviewId:guid}/moderate")]
    [Authorize]
    public async Task<IActionResult> ModerateReview(Guid reviewId, [FromBody] ModerateRequest request, CancellationToken ct)
    {
        var dto = await _reviewService.ModerateAsync(reviewId, CurrentUserId, request.Action, ct);
        return Ok(dto);
    }

    // ── Comments ──────────────────────────────────────────────────────────

    [HttpPost("dishes/{dishId:guid}/comment")]
    [Authorize]
    public async Task<IActionResult> CreateComment(Guid dishId, [FromBody] CreateCommentRequest request, CancellationToken ct)
    {
        var dto = await _commentService.CreateAsync(dishId, CurrentUserId, request, ct);
        return StatusCode(201, dto);
    }

    [HttpGet("dishes/{dishId:guid}/comments")]
    public async Task<IActionResult> GetApprovedComments(Guid dishId, CancellationToken ct)
    {
        var comments = await _commentService.GetApprovedByDishAsync(dishId, ct);
        return Ok(comments);
    }

    [HttpGet("comments/pending")]
    [Authorize]
    public async Task<IActionResult> GetPendingComments(CancellationToken ct)
    {
        var restaurant = await _restaurantService.GetByOwnerIdAsync(CurrentUserId, ct);
        if (restaurant == null) return Ok(Array.Empty<object>());
        var comments = await _commentService.GetPendingByRestaurantAsync(restaurant.Id, ct);
        return Ok(comments);
    }

    [HttpPut("comments/{commentId:guid}/moderate")]
    [Authorize]
    public async Task<IActionResult> ModerateComment(Guid commentId, [FromBody] ModerateRequest request, CancellationToken ct)
    {
        var dto = await _commentService.ModerateAsync(commentId, CurrentUserId, request.Action, ct);
        return Ok(dto);
    }
}
