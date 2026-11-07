using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Restaurant;

public record CreateRestaurantRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(1000)] string? Description,
    [Required, MaxLength(500)] string Address,
    double Latitude,
    double Longitude,
    [Required, MaxLength(100)] string Category,
    [MaxLength(100)] string City = "Salvador",
    [MaxLength(500)] string? LogoUrl = null,
    [MaxLength(500)] string? CoverUrl = null,
    [MaxLength(500)] string? InstagramUrl = null,
    [MaxLength(500)] string? YouTubeVideoUrl = null,
    string? OpeningHours = null,
    int TotalTables = 0,
    bool HasEventSpace = false,
    int? EventSpaceCapacity = null,
    bool AllowsReservations = false,
    int TablesAvailableForReservation = 0
);
