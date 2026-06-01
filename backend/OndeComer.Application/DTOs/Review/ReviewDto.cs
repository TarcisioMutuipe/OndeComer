namespace OndeComer.Application.DTOs.Review;

public record ReviewDto(
    Guid Id,
    int Rating,
    string Status,
    string UserName,
    DateTime CreatedAt
);
