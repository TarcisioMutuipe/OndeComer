using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class PasswordResetTokenRepository : IPasswordResetTokenRepository
{
    private readonly AppDbContext _context;
    public PasswordResetTokenRepository(AppDbContext context) => _context = context;

    public async Task AddAsync(PasswordResetToken token, CancellationToken ct = default)
        => await _context.PasswordResetTokens.AddAsync(token, ct);

    public async Task<PasswordResetToken?> GetByTokenAsync(string token, CancellationToken ct = default)
        => await _context.PasswordResetTokens
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.Token == token, ct);
}
