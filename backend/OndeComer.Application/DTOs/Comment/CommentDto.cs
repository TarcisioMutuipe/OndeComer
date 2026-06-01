namespace OndeComer.Application.DTOs.Comment;

public record CommentDto(
    Guid Id,
    Guid DishId,
    string DishName,
    string Text,
    string Status,
    string UserName,
    DateTime CreatedAt
);
