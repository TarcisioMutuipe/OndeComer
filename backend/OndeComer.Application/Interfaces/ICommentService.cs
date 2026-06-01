using OndeComer.Application.DTOs.Comment;

namespace OndeComer.Application.Interfaces;

public interface ICommentService
{
    Task<CommentDto> CreateAsync(Guid dishId, Guid userId, CreateCommentRequest request, CancellationToken ct = default);
    Task<IEnumerable<CommentDto>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default);
    Task<IEnumerable<CommentDto>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default);
    Task<CommentDto> ModerateAsync(Guid commentId, Guid moderatedByUserId, string action, CancellationToken ct = default);
    Task DeleteAsync(Guid commentId, CancellationToken ct = default);
}
