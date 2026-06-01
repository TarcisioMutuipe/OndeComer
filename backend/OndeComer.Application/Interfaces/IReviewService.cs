using OndeComer.Application.DTOs.Review;

namespace OndeComer.Application.Interfaces;

public interface IReviewService
{
    Task<ReviewDto> CreateAsync(Guid dishId, Guid userId, CreateReviewRequest request, CancellationToken ct = default);
    Task<IEnumerable<ReviewDto>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default);
    Task<IEnumerable<ReviewDto>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default);
    Task<ReviewDto> ModerateAsync(Guid reviewId, Guid moderatedByUserId, string action, CancellationToken ct = default);
}
