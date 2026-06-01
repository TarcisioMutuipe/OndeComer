using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IEmailConfirmationTokenRepository
{
    Task AddAsync(EmailConfirmationToken token, CancellationToken ct = default);
    Task<EmailConfirmationToken?> GetByTokenAsync(string token, CancellationToken ct = default);
}
