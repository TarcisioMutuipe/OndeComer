using Microsoft.EntityFrameworkCore;
using OndeComer.Domain.Entities;
using OndeComer.Domain.Interfaces;
using OndeComer.Infrastructure.Data;

namespace OndeComer.Infrastructure.Repositories;

public class UploadedImageRepository : IUploadedImageRepository
{
    private readonly AppDbContext _context;

    public UploadedImageRepository(AppDbContext context) => _context = context;

    public async Task AddAsync(UploadedImage image, CancellationToken ct = default)
        => await _context.UploadedImages.AddAsync(image, ct);

    public async Task<IEnumerable<UploadedImage>> GetByEntityAsync(string entityType, Guid entityId, CancellationToken ct = default)
        => await _context.UploadedImages
            .Where(i => i.EntityType == entityType && i.EntityId == entityId)
            .OrderByDescending(i => i.CreatedAt)
            .ToListAsync(ct);

    public Task<UploadedImage?> GetByRelativePathAsync(string relativePath, CancellationToken ct = default)
        => _context.UploadedImages.FirstOrDefaultAsync(i => i.RelativePath == relativePath, ct);

    public void Delete(UploadedImage image) => _context.UploadedImages.Remove(image);
}
