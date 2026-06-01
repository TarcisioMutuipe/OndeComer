namespace OndeComer.Application.DTOs.Auth;

public record UpdateProfileRequest(
    string? Name,
    string? Address,
    string? PreferredLanguage
);
