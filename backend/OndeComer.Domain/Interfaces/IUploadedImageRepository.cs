using OndeComer.Domain.Entities;

namespace OndeComer.Domain.Interfaces;

public interface IUploadedImageRepository
{
    Task AddAsync(UploadedImage image, CancellationToken ct = default);
    Task<IEnumerable<UploadedImage>> GetByEntityAsync(string entityType, Guid entityId, CancellationToken ct = default);
    Task<UploadedImage?> GetByRelativePathAsync(string relativePath, CancellationToken ct = default);
    void Delete(UploadedImage image);
}
