namespace OndeComer.Application.DTOs.Restaurant;

public record RestaurantFilterRequest(
    string? Search = null,
    string? Category = null,
    string? City = null,
    int Page = 1,
    int PageSize = 20
);
