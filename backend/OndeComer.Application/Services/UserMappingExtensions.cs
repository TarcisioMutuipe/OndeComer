using OndeComer.Application.DTOs.Auth;
using OndeComer.Domain.Entities;

namespace OndeComer.Application.Services;

public static class UserMappingExtensions
{
    public static UserDto ToDto(this User user) => new(
        user.Id,
        user.Name,
        user.Email,
        user.Username,
        user.Address,
        user.ProfileType,
        user.PreferredLanguage,
        user.EmailConfirmed,
        user.CreatedAt
    );
}
