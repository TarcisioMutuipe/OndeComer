using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Events;

public record CreateCityEventRequest(
    [Required, MaxLength(200)] string Title,
    [Required] string Description,
    [Required, MaxLength(500)] string ImageUrl,
    [MaxLength(500)] string? YouTubeVideoUrl,
    [MaxLength(300)] string? LocationOrAddress,
    DateTime? EventDate,
    Guid? RestaurantId
);

public record UpdateCityEventRequest(
    [MaxLength(200)] string? Title,
    string? Description,
    [MaxLength(500)] string? ImageUrl,
    [MaxLength(500)] string? YouTubeVideoUrl,
    [MaxLength(300)] string? LocationOrAddress,
    DateTime? EventDate,
    Guid? RestaurantId,
    bool? IsActive
);

public record CityEventDto(
    Guid Id,
    string Title,
    string Description,
    string ImageUrl,
    string? YouTubeVideoUrl,
    string? LocationOrAddress,
    DateTime? EventDate,
    Guid? RestaurantId,
    string? RestaurantName,
    bool IsActive,
    int LikesCount,
    int DislikesCount,
    bool? UserReaction, // true = like, false = dislike, null = none
    DateTime CreatedAt
);

public record ReactToEventRequest(
    bool IsLike
);

public record ReactToEventResultDto(
    Guid EventId,
    int LikesCount,
    int DislikesCount,
    bool? CurrentReaction // null if removed, true if liked, false if disliked
);

