using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Comment;
using OndeComer.Application.DTOs.Moderation;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Enums;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Application.Services;

public class CommentService : ICommentService
{
    private readonly IUnitOfWork _uow;
    private readonly IModerationService? _moderationService;

    public CommentService(IUnitOfWork uow, IModerationService? moderationService = null)
    {
        _uow = uow;
        _moderationService = moderationService;
    }

    public async Task<CommentDto> CreateAsync(Guid dishId, Guid userId, CreateCommentRequest request, CancellationToken ct = default)
    {
        var dish = await _uow.Dishes.GetByIdAsync(dishId, ct)
            ?? throw new NotFoundException("Prato não encontrado.");

        var user = await _uow.Users.GetByIdAsync(userId, ct)
            ?? throw new NotFoundException("Usuário não encontrado.");

        // AI moderation scan
        var status = ReviewStatus.Pending;
        if (_moderationService != null)
        {
            var modResult = await _moderationService.ScanTextAsync(new ScanTextRequest(
                request.Text, "comment", null, userId));

            if (modResult.Result == "blocked")
                throw new AppException("Seu comentário foi bloqueado por conter conteúdo inadequado.", 422);
            if (modResult.Result == "approved")
                status = ReviewStatus.Approved;
            // "flagged" stays as Pending for human review
        }

        var comment = new Comment
        {
            DishId = dishId,
            UserId = userId,
            Text = request.Text,
            Status = status,
        };

        await _uow.Comments.AddAsync(comment, ct);
        await _uow.CommitAsync(ct);

        return ToDto(comment, dish.Name, user.Name);
    }

    public async Task<IEnumerable<CommentDto>> GetApprovedByDishAsync(Guid dishId, CancellationToken ct = default)
    {
        var comments = await _uow.Comments.GetApprovedByDishAsync(dishId, ct);
        return comments.Select(c => ToDto(c, c.Dish?.Name ?? "", c.User?.Name ?? "Usuário"));
    }

    public async Task<IEnumerable<CommentDto>> GetPendingByRestaurantAsync(Guid restaurantId, CancellationToken ct = default)
    {
        var comments = await _uow.Comments.GetPendingByRestaurantAsync(restaurantId, ct);
        return comments.Select(c => ToDto(c, c.Dish?.Name ?? "", c.User?.Name ?? "Usuário"));
    }

    public async Task<CommentDto> ModerateAsync(Guid commentId, Guid moderatedByUserId, string action, CancellationToken ct = default)
    {
        var comment = await _uow.Comments.GetByIdAsync(commentId, ct)
            ?? throw new NotFoundException("Comentário não encontrado.");

        if (comment.Status != ReviewStatus.Pending)
            throw new AppException("Este comentário já foi moderado.", 409);

        var normalizedAction = action.Trim().ToLowerInvariant();
        if (normalizedAction == "approve")
        {
            comment.Status = ReviewStatus.Approved;
            comment.ModeratedAt = DateTime.UtcNow;
            comment.ModeratedByUserId = moderatedByUserId;
        }
        else if (normalizedAction == "reject")
        {
            comment.Status = ReviewStatus.Rejected;
            comment.ModeratedAt = DateTime.UtcNow;
            comment.ModeratedByUserId = moderatedByUserId;
        }
        else
        {
            throw new AppException("Ação inválida. Use 'approve' ou 'reject'.", 400);
        }

        await _uow.CommitAsync(ct);

        var dish = await _uow.Dishes.GetByIdAsync(comment.DishId, ct);
        var user = await _uow.Users.GetByIdAsync(comment.UserId, ct);
        return ToDto(comment, dish?.Name ?? "", user?.Name ?? "Usuário");
    }

    private static CommentDto ToDto(Comment c, string dishName, string userName) =>
        new(c.Id, c.DishId, dishName, c.Text, c.Status.ToString(), userName, c.CreatedAt);

    public async Task DeleteAsync(Guid commentId, CancellationToken ct = default)
    {
        var comment = await _uow.Comments.GetByIdAsync(commentId, ct)
            ?? throw new NotFoundException("Comentário não encontrado.");

        _uow.Comments.Delete(comment);
        await _uow.CommitAsync(ct);
    }
}
