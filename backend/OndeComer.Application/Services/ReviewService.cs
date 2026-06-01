using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Review;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Application.Services;

public class ReviewService : IReviewService
{
    private readonly IUnitOfWork _uow;

    public ReviewService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<ReviewDto> CreateAsync(Guid dishId, Guid userId, CreateReviewRequest request, CancellationToken ct = default)
    {
        var dish = await _uow.Dishes.GetByIdAsync(dishId, ct)
            ?? throw new NotFoundException("Prato não encontrado.");

        if (await _uow.Reviews.ExistsAsync(dishId, userId, ct))
            throw new ConflictException("Você já avaliou este prato.");

        var user = await _uow.Users.GetByIdAsync(userId, ct)
            ?? throw new NotFoundException("Usuário não encontrado.");

        var review = new Review
        {
            DishId = dishId,
            UserId = userId,
            Rating = request.Rating,
            Status = ReviewStatus.Pending,
        };

        await _uow.Reviews.AddAsync(review, ct);
        await _uow.CommitAsync(ct);

        return ToDto(review, user.Name);
    }

    public async Task<IEnumerable<ReviewDto>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default)
    {
        var reviews = await _uow.Reviews.GetApprovedByDishAsync(dishId, ct);
        return reviews.Select(r => ToDto(r, r.User?.Name ?? "Usuário"));
    }

    public async Task<IEnumerable<ReviewDto>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var reviews = await _uow.Reviews.GetPendingByRestaurantAsync(restaurantId, ct);
        return reviews.Select(r => ToDto(r, r.User?.Name ?? "Usuário"));
    }

    public async Task<ReviewDto> ModerateAsync(Guid reviewId, Guid moderatedByUserId, string action, CancellationToken ct = default)
    {
        var review = await _uow.Reviews.GetByIdAsync(reviewId, ct)
            ?? throw new NotFoundException("Avaliação não encontrada.");

        if (review.Status != ReviewStatus.Pending)
            throw new AppException("Esta avaliação já foi moderada.", 409);

        var normalizedAction = action.Trim().ToLowerInvariant();
        if (normalizedAction == "approve")
        {
            review.Status = ReviewStatus.Approved;
            review.ModeratedAt = DateTime.UtcNow;
            review.ModeratedByUserId = moderatedByUserId;

            // Recalculate dish rating
            var (avg, count) = await _uow.Reviews.GetRatingStatsAsync(review.DishId, ct);
            // +1 to include this review that's being approved now
            var newCount = count + 1;
            var newAvg = ((avg * count) + review.Rating) / newCount;

            var dish = await _uow.Dishes.GetByIdAsync(review.DishId, ct);
            if (dish != null)
            {
                dish.RatingAverage = Math.Round(newAvg, 2);
                dish.RatingCount = newCount;
                _uow.Dishes.Update(dish);
            }
        }
        else if (normalizedAction == "reject")
        {
            review.Status = ReviewStatus.Rejected;
            review.ModeratedAt = DateTime.UtcNow;
            review.ModeratedByUserId = moderatedByUserId;
        }
        else
        {
            throw new AppException("Ação inválida. Use 'approve' ou 'reject'.", 400);
        }

        await _uow.CommitAsync(ct);

        var user = await _uow.Users.GetByIdAsync(review.UserId, ct);
        return ToDto(review, user?.Name ?? "Usuário");
    }

    private static ReviewDto ToDto(Review r, string userName) =>
        new(r.Id, r.Rating, r.Status.ToString(), userName, r.CreatedAt);
}
