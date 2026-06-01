using OndeComer.Domain.Enums;

namespace OndeComer.Application.DTOs.Auth;

public record UserDto(
    Guid Id,
    string Name,
    string Email,
    string Username,
    string? Address,
    ProfileType ProfileType,
    string PreferredLanguage,
    bool EmailConfirmed,
    DateTime CreatedAt
);
