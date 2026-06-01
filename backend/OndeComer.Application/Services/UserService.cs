using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Auth;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Interfaces;

namespace OndeComer.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _uow;

    public UserService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<UserDto> GetCurrentUserAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByIdAsync(userId, ct)
            ?? throw new NotFoundException("Usuário não encontrado.");

        return user.ToDto();
    }

    public async Task<UserDto> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByIdAsync(userId, ct)
            ?? throw new NotFoundException("Usuário não encontrado.");

        if (!string.IsNullOrWhiteSpace(request.Name))
            user.Name = request.Name.Trim();

        if (request.Address is not null)
            user.Address = request.Address.Trim();

        if (!string.IsNullOrWhiteSpace(request.PreferredLanguage))
            user.PreferredLanguage = request.PreferredLanguage;

        await _uow.Users.UpdateAsync(user, ct);
        await _uow.CommitAsync(ct);

        return user.ToDto();
    }

    public async Task<bool> CheckEmailAvailableAsync(string email, CancellationToken ct = default)
        => !await _uow.Users.EmailExistsAsync(email.Trim().ToLowerInvariant(), ct);

    public async Task<bool> CheckUsernameAvailableAsync(string username, CancellationToken ct = default)
        => !await _uow.Users.UsernameExistsAsync(username.Trim().ToLowerInvariant(), ct);
}
