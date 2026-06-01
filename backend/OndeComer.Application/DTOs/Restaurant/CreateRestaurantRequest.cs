using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Restaurant;

public record CreateRestaurantRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(1000)] string? Description,
    [Required, MaxLength(500)] string Address,
    [MaxLength(100)] string City,
    double Latitude,
    double Longitude,
    [Required, MaxLength(100)] string Category,
    [MaxLength(500)] string? LogoUrl,
    [MaxLength(500)] string? CoverUrl,
    [MaxLength(500)] string? InstagramUrl,
    [MaxLength(500)] string? YouTubeVideoUrl,
    string? OpeningHours
);
