namespace OndeComer.Application.DTOs.Auth;

public record RegisterRequest(
    string Name,
    string Email,
    string Password,
    string? Username = null,
    string? Address = null,
    string PreferredLanguage = "pt-BR",
    string ProfileType = "Consumer"
);
