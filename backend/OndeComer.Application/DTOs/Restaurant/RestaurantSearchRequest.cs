using System.ComponentModel.DataAnnotations;

namespace OndeComer.Application.DTOs.Restaurant;

public record RestaurantSearchRequest(
    string? Query = null,
    string? Category = null,
    decimal? MinPrice = null,
    decimal? MaxPrice = null,
    double? MinRating = null,
    double? Lat = null,
    double? Lng = null,
    [Range(0.1, 50)] double? Radius = null,   // km
    bool? IsOpenNow = null,
    string SortBy = "relevance",              // relevance | distance | rating | name
    string SortOrder = "asc",                 // asc | desc
    int Page = 1,
    [Range(1, 50)] int PageSize = 20
);
