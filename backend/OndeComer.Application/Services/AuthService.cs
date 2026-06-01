using Microsoft.Extensions.Configuration;
using OndeComer.Application.Common.Exceptions;
using OndeComer.Application.DTOs.Auth;
using OndeComer.Application.Interfaces;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using BCrypt.Net;
using Google.Apis.Auth;
using System.Security.Cryptography;

namespace OndeComer.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _uow;
    private readonly ITokenService _tokenService;
    private readonly IEmailService _emailService;
    private readonly string _googleClientId;

    public AuthService(IUnitOfWork uow, ITokenService tokenService, IEmailService emailService, IConfiguration configuration)
    {
        _uow = uow;
        _tokenService = tokenService;
        _emailService = emailService;
        _googleClientId = configuration["Google:ClientId"] ?? throw new InvalidOperationException("Google:ClientId não configurado.");
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        if (await _uow.Users.EmailExistsAsync(request.Email, ct))
            throw new ConflictException("Este e-mail já está em uso.");

        if (await _uow.Users.UsernameExistsAsync(request.Username, ct))
            throw new ConflictException("Este nome de usuário já está em uso.");

        // Auto-generate username from email if not provided
        var baseUsername = (!string.IsNullOrWhiteSpace(request.Username)
            ? request.Username.Trim()
            : request.Email.Split('@')[0])
            .ToLowerInvariant()
            .Replace(" ", "_");

        var username = baseUsername;
        var suffix = 1;
        while (await _uow.Users.UsernameExistsAsync(username, ct))
            username = $"{baseUsername}{suffix++}";

        // Map profileType string to enum (default: Consumer)
        var profileType = request.ProfileType?.Trim() switch
        {
            "Restaurant" or "Restaurante" => Domain.Enums.ProfileType.Restaurant,
            "Admin" => Domain.Enums.ProfileType.Admin,
            _ => Domain.Enums.ProfileType.Consumer
        };

        var user = new User
        {
            Name = request.Name.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            Username = username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Address = request.Address?.Trim(),
            PreferredLanguage = request.PreferredLanguage,
            ProfileType = profileType,
            EmailConfirmed = false // confirmação via email
        };

        await _uow.Users.AddAsync(user, ct);
        await _uow.CommitAsync(ct);

        var authResponse = await IssueTokensAsync(user, ct);

        // Enviar email de confirmação (sequencial, após tokens emitidos)
        try { await SendEmailConfirmationAsync(user.Email, ct); }
        catch { /* silencioso — não bloqueia o registro */ }

        return authResponse;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByEmailAsync(request.Email.Trim().ToLowerInvariant(), ct)
            ?? throw new UnauthorizedException("E-mail ou senha inválidos.");

        if (!user.IsActive)
            throw new UnauthorizedException("Conta desativada.");

        if (string.IsNullOrEmpty(user.PasswordHash) || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedException("E-mail ou senha inválidos.");

        user.LastLogin = DateTime.UtcNow;
        await _uow.Users.UpdateAsync(user, ct);
        await _uow.CommitAsync(ct);

        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> GoogleLoginAsync(GoogleAuthRequest request, CancellationToken ct = default)
    {
        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(
                request.IdToken,
                new GoogleJsonWebSignature.ValidationSettings { Audience = new[] { _googleClientId } }
            );
        }
        catch
        {
            throw new UnauthorizedException("Token Google inválido.");
        }

        var user = await _uow.Users.GetByGoogleSubAsync(payload.Subject, ct);

        if (user is null)
        {
            user = await _uow.Users.GetByEmailAsync(payload.Email, ct);

            if (user is not null)
            {
                user.GoogleSub = payload.Subject;
                user.EmailConfirmed = true;
            }
            else
            {
                var username = await GenerateUniqueUsernameAsync(payload.Email, ct);
                user = new User
                {
                    Name = payload.Name ?? payload.Email,
                    Email = payload.Email.ToLowerInvariant(),
                    Username = username,
                    GoogleSub = payload.Subject,
                    EmailConfirmed = true
                };
                await _uow.Users.AddAsync(user, ct);
            }
        }

        if (!user.IsActive)
            throw new UnauthorizedException("Conta desativada.");

        user.LastLogin = DateTime.UtcNow;
        await _uow.Users.UpdateAsync(user, ct);
        await _uow.CommitAsync(ct);

        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        var refreshToken = await _uow.RefreshTokens.GetByTokenAsync(request.RefreshToken, ct)
            ?? throw new UnauthorizedException("Refresh token inválido.");

        if (refreshToken.IsRevoked || refreshToken.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedException("Refresh token expirado ou revogado.");

        var user = await _uow.Users.GetByIdAsync(refreshToken.UserId, ct)
            ?? throw new UnauthorizedException("Usuário não encontrado.");

        if (!user.IsActive)
            throw new UnauthorizedException("Conta desativada.");

        await _uow.RefreshTokens.RevokeAsync(request.RefreshToken, ct);
        await _uow.CommitAsync(ct);

        return await IssueTokensAsync(user, ct);
    }

    public async Task LogoutAsync(string refreshToken, CancellationToken ct = default)
    {
        await _uow.RefreshTokens.RevokeAsync(refreshToken, ct);
        await _uow.CommitAsync(ct);
    }

    private async Task<AuthResponse> IssueTokensAsync(User user, CancellationToken ct)
    {
        var accessToken = _tokenService.GenerateAccessToken(user);
        var rawRefresh = _tokenService.GenerateRefreshToken();
        var expiresAt = DateTime.UtcNow.AddMinutes(15);

        var refreshTokenEntity = new RefreshToken
        {
            Token = rawRefresh,
            UserId = user.Id,
            ExpiresAt = DateTime.UtcNow.AddDays(7)
        };

        await _uow.RefreshTokens.AddAsync(refreshTokenEntity, ct);
        await _uow.CommitAsync(ct);

        return new AuthResponse(accessToken, rawRefresh, expiresAt, user.ToDto());
    }

    private async Task<string> GenerateUniqueUsernameAsync(string email, CancellationToken ct)
    {
        var baseUsername = email.Split('@')[0].ToLowerInvariant().Replace(".", "_");
        var candidate = baseUsername;
        var suffix = 1;

        while (await _uow.Users.UsernameExistsAsync(candidate, ct))
        {
            candidate = $"{baseUsername}{suffix++}";
        }

        return candidate;
    }

    public async Task SendEmailConfirmationAsync(string email, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByEmailAsync(email.Trim().ToLowerInvariant(), ct);
        if (user == null || user.EmailConfirmed) return; // silencioso para evitar enumeração

        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var confirmToken = new EmailConfirmationToken
        {
            UserId = user.Id,
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddHours(24)
        };

        await _uow.EmailConfirmationTokens.AddAsync(confirmToken, ct);
        await _uow.CommitAsync(ct);

        await _emailService.SendEmailConfirmationAsync(user.Email, user.Name, token, ct);
    }

    public async Task<bool> ConfirmEmailAsync(string email, string token, CancellationToken ct = default)
    {
        var confirmToken = await _uow.EmailConfirmationTokens.GetByTokenAsync(token, ct);
        if (confirmToken == null || confirmToken.Used || confirmToken.ExpiresAt < DateTime.UtcNow)
            return false;

        var user = await _uow.Users.GetByIdAsync(confirmToken.UserId, ct);
        if (user == null || user.Email.ToLowerInvariant() != email.Trim().ToLowerInvariant())
            return false;

        user.EmailConfirmed = true;
        confirmToken.Used = true;
        await _uow.Users.UpdateAsync(user, ct);
        await _uow.CommitAsync(ct);

        await _emailService.SendWelcomeAsync(user.Email, user.Name, ct);
        return true;
    }

    public async Task RequestPasswordResetAsync(string email, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByEmailAsync(email.Trim().ToLowerInvariant(), ct);
        if (user == null) return; // silencioso

        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var resetToken = new PasswordResetToken
        {
            UserId = user.Id,
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddHours(1)
        };

        await _uow.PasswordResetTokens.AddAsync(resetToken, ct);
        await _uow.CommitAsync(ct);

        await _emailService.SendPasswordResetAsync(user.Email, user.Name, token, ct);
    }

    public async Task ResetPasswordAsync(string email, string token, string newPassword, CancellationToken ct = default)
    {
        var resetToken = await _uow.PasswordResetTokens.GetByTokenAsync(token, ct)
            ?? throw new UnauthorizedException("Token de redefinição inválido.");

        if (resetToken.Used || resetToken.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedException("Token expirado.");

        var user = await _uow.Users.GetByIdAsync(resetToken.UserId, ct)
            ?? throw new UnauthorizedException("Usuário não encontrado.");

        if (user.Email.ToLowerInvariant() != email.Trim().ToLowerInvariant())
            throw new UnauthorizedException("Token de redefinição inválido.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        resetToken.Used = true;
        await _uow.Users.UpdateAsync(user, ct);
        await _uow.CommitAsync(ct);
    }
}
