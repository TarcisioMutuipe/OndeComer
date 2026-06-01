using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class EmailConfirmationTokenRepository : IEmailConfirmationTokenRepository
{
    private readonly AppDbContext _context;
    public EmailConfirmationTokenRepository(AppDbContext context) => _context = context;

    public async Task AddAsync(EmailConfirmationToken token, CancellationToken ct = default)
        => await _context.EmailConfirmationTokens.AddAsync(token, ct);

    public async Task<EmailConfirmationToken?> GetByTokenAsync(string token, CancellationToken ct = default)
        => await _context.EmailConfirmationTokens
            .Include(e => e.User)
            .FirstOrDefaultAsync(e => e.Token == token, ct);
}
