using OndeComer.Domain.Entities;

namespace OndeComer.Application.Interfaces;

public interface ITokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    Guid? ValidateAccessTokenAndGetUserId(string token);
}
