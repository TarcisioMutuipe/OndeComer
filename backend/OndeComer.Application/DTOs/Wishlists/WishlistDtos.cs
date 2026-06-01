using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Wishlists;

public record WishlistDto(
    Guid Id,
    Guid UserId,
    string Name,
    string? Description,
    bool IsPublic,
    string? ShareToken,
    string? ShareUrl,
    int ItemCount,
    List<WishlistItemDto> Items,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

public record WishlistItemDto(
    Guid Id,
    Guid WishlistId,
    Guid? RestaurantId,
    string? RestaurantName,
    string? RestaurantLogoUrl,
    Guid? DishId,
    string? DishName,
    string? DishImageUrl,
    string? Note,
    DateTime CreatedAt
);

public record CreateWishlistRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(1000)] string? Description,
    bool IsPublic = false
);

public record UpdateWishlistRequest(
    [MaxLength(200)] string? Name,
    [MaxLength(1000)] string? Description,
    bool? IsPublic
);

public record AddWishlistItemRequest(
    Guid? RestaurantId,
    Guid? DishId,
    [MaxLength(500)] string? Note
);
