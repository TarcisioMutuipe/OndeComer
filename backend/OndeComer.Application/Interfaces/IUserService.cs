using OndeComer.Application.DTOs.Auth;

namespace OndeComer.Application.Interfaces;

public interface IUserService
{
    Task<UserDto> GetCurrentUserAsync(Guid userId, CancellationToken ct = default);
    Task<UserDto> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken ct = default);
    Task<bool> CheckEmailAvailableAsync(string email, CancellationToken ct = default);
    Task<bool> CheckUsernameAvailableAsync(string username, CancellationToken ct = default);
}
