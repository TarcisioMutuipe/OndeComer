using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Restaurant;

public record UpdateRestaurantRequest(
    [MaxLength(200)] string? Name,
    [MaxLength(1000)] string? Description,
    [MaxLength(500)] string? Address,
    [MaxLength(100)] string? City,
    double? Latitude,
    double? Longitude,
    [MaxLength(100)] string? Category,
    [MaxLength(500)] string? LogoUrl,
    [MaxLength(500)] string? CoverUrl,
    [MaxLength(500)] string? InstagramUrl,
    [MaxLength(500)] string? YouTubeVideoUrl,
    string? OpeningHours,
    bool? IsActive
);
